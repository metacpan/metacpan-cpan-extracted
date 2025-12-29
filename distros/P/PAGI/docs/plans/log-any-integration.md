# Log::Any Integration Plan

## Overview

Add optional Log::Any support with proper separation of concerns:

| Component | Responsibility | Log::Any Support |
|-----------|----------------|------------------|
| `PAGI::Server` | Server operational logs only | `logger` option |
| `PAGI::Middleware::AccessLog` | HTTP request/response logs | `logger` option |
| `PAGI::Runner` | App loading, middleware composition | `--access-log` wraps app in middleware |

This follows the Plack pattern where access logging is middleware, not a server concern.

## Architecture Change

### Current (Coupled)

```
PAGI::Server
├── Operational logs (warn to STDERR)
└── Access logs (access_log filehandle)  ← Server shouldn't own this
```

### Proposed (Separated)

```
PAGI::Runner
└── --access-log wraps app in AccessLog middleware

PAGI::Server
└── Operational logs only (logger option)

PAGI::Middleware::AccessLog
└── Request/response logs (logger option)
```

## Part 1: PAGI::Server Logging

### Current State

```perl
sub _log {
    my ($self, $level, $msg) = @_;
    my $level_num = $_LOG_LEVELS{$level} // 2;
    return if $level_num < $self->{_log_level_num};
    return if $self->{quiet} && $level ne 'error';
    warn "$msg\n";  # Always STDERR, not configurable
}
```

### Proposed: `logger` Option

```perl
PAGI::Server->new(
    app    => $app,
    logger => 'Log::Any',        # Use Log::Any
    # OR
    logger => sub { ... },       # Custom callback
    # OR (default)
    # Uses warn() to STDERR
);
```

### Implementation

**1.1 Add `logger` option parsing in `_init()`**

```perl
$self->{logger} = delete $params->{logger};
$self->{_logger} = $self->_build_logger();
```

**1.2 Build logger based on spec**

```perl
sub _build_logger {
    my ($self) = @_;
    my $spec = $self->{logger};

    # Default: warn-based logging
    return undef unless defined $spec;

    # Custom callback
    return $spec if ref $spec eq 'CODE';

    # Log::Any
    if ($spec eq 'Log::Any') {
        eval { require Log::Any }
            or die "logger => 'Log::Any' requires Log::Any to be installed\n";

        my $log = Log::Any->get_logger(category => 'PAGI::Server');

        my %level_map = (
            debug => 'debug',
            info  => 'info',
            warn  => 'warning',  # Log::Any uses 'warning'
            error => 'error',
        );

        return sub {
            my ($level, $msg, $ctx) = @_;
            my $method = $level_map{$level} // 'info';
            $log->$method($msg);
        };
    }

    die "Invalid logger specification: $spec\n";
}
```

**1.3 Refactor `_log()` method**

```perl
sub _log {
    my ($self, $level, $msg, $ctx) = @_;

    my $level_num = $_LOG_LEVELS{$level} // 2;
    return if $level_num < $self->{_log_level_num};
    return if $self->{quiet} && $level ne 'error';

    if (my $logger = $self->{_logger}) {
        $logger->($level, $msg, $ctx);
    } else {
        warn "$msg\n";
    }
}
```

**1.4 Deprecate `access_log` option**

```perl
# In _init()
if (exists $params->{access_log}) {
    warn "PAGI::Server access_log option is deprecated. "
       . "Use PAGI::Middleware::AccessLog instead.\n";
    delete $params->{access_log};
}
```

**1.5 Remove access logging code from Server**

Remove all `$self->{access_log}` writes from request handling code.

**1.6 Propagate to workers**

```perl
# In _create_worker_server()
my $worker_server = PAGI::Server->new(
    ...
    logger => $self->{logger},
);
```

### POD Documentation

```pod
=item logger => $logger_spec

Logging backend for server operational messages (startup, shutdown, signals,
worker lifecycle, errors).

B<Values:>

=over 4

=item C<undef> or omitted (default)

Uses Perl's C<warn()> to send messages to STDERR.

=item C<'Log::Any'>

Routes messages through L<Log::Any> with category C<PAGI::Server>:

    use Log::Any::Adapter ('Syslog', ident => 'pagi');

    my $server = PAGI::Server->new(
        app    => $app,
        logger => 'Log::Any',
    );

=item C<sub { my ($level, $msg, $ctx) = @_; ... }>

Custom callback receiving level (debug/info/warn/error), message string,
and optional context hashref.

=back

B<Note:> For HTTP access logs, use L<PAGI::Middleware::AccessLog>.
```

## Part 2: PAGI::Middleware::AccessLog Enhancement

### Current State

Check existing implementation:

```perl
# PAGI::Middleware::AccessLog
# Currently uses filehandle-based logging
```

### Proposed: Add `logger` Option

```perl
use PAGI::Middleware::AccessLog;

# Filehandle (existing behavior)
AccessLog->new(logger => \*STDERR)->wrap($app);

# Log::Any
AccessLog->new(
    logger   => 'Log::Any',
    category => 'MyApp::Access',  # optional, default: PAGI::AccessLog
)->wrap($app);

# Custom callback
AccessLog->new(
    logger => sub {
        my ($message, $context) = @_;
        # $context: { method, path, status, duration_ms, client_ip, bytes }
    },
)->wrap($app);
```

### Implementation

**2.1 Update constructor**

```perl
sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);

    $self->{logger}   = $args{logger} // \*STDOUT;  # stdout for access logs
    $self->{category} = $args{category} // 'PAGI::AccessLog';
    $self->{format}   = $args{format} // 'combined';  # or 'common', 'json'

    $self->{_log_func} = $self->_build_log_func();

    return $self;
}
```

**2.2 Build logging function**

```perl
sub _build_log_func {
    my ($self) = @_;
    my $spec = $self->{logger};

    # Filehandle
    if (ref $spec eq 'GLOB' || (blessed($spec) && $spec->can('print'))) {
        return sub {
            my ($msg, $ctx) = @_;
            print $spec "$msg\n";
        };
    }

    # Custom callback
    return $spec if ref $spec eq 'CODE';

    # Log::Any
    if ($spec eq 'Log::Any') {
        eval { require Log::Any }
            or die "logger => 'Log::Any' requires Log::Any\n";

        my $log = Log::Any->get_logger(category => $self->{category});

        return sub {
            my ($msg, $ctx) = @_;
            $log->info($msg, $ctx);
        };
    }

    die "Invalid logger specification for AccessLog\n";
}
```

**2.3 Update logging call**

```perl
# After request completes:
$self->{_log_func}->(
    $self->_format_line($scope, $status, $bytes, $duration),
    {
        client_ip   => $scope->{client}[0],
        method      => $scope->{method},
        path        => $scope->{path},
        status      => $status,
        bytes       => $bytes,
        duration_ms => $duration * 1000,
        user_agent  => $scope->{headers}{'user-agent'} // '-',
        referer     => $scope->{headers}{referer} // '-',
    }
);
```

## Part 3: PAGI::Runner Updates

### Current State

Runner already has environment modes (`-E` / `--env`) with these defaults:
- Development: access log to STDERR (via Server's access_log option)
- Production: access log disabled

CLI options exist: `--access-log FILE`, `--no-access-log`

### Change: Use Middleware Instead of Server Option

Instead of passing `access_log` to PAGI::Server, wrap app in AccessLog middleware.
This makes access logging server-agnostic.

**CLI options unchanged:**
```
-E, --env MODE       Environment mode (development, production, none)
--access-log FILE    Write access log to FILE
--access-log -       Write access log to STDERR (explicit)
--no-access-log      Disable access logging
```

**Behavior unchanged:**
```bash
pagi-server --app app.pl                 # Development: access log to STDERR
pagi-server -E production --app app.pl   # Production: no access log
pagi-server --no-access-log --app app.pl # Explicit disable
pagi-server --access-log /var/log/x.log  # Explicit file
```

### Implementation

**3.1 Refactor _build_server to wrap app in middleware**

```perl
sub _build_server {
    my ($self) = @_;
    my $server_class = $self->_load_server_class;
    my %server_opts = $self->_parse_server_options($server_class);

    # Wrap app in AccessLog middleware (instead of passing to Server)
    my $app = $self->_wrap_with_access_log($self->{app});

    return $server_class->new(
        app   => $app,  # Now wrapped with middleware
        host  => $self->{host} // '127.0.0.1',
        port  => $self->{port} // 5000,
        quiet => $self->{quiet} // 0,
        # NO access_log option - middleware handles it now
        %server_opts,
    );
}

sub _wrap_with_access_log {
    my ($self, $app) = @_;

    # Determine if access logging enabled
    my $log_dest;

    if ($self->{no_access_log}) {
        return $app;  # Explicit disable
    }
    elsif (defined $self->{access_log}) {
        $log_dest = $self->{access_log};  # Explicit file or '-'
    }
    elsif ($self->mode eq 'development') {
        $log_dest = '-';  # Development default: STDERR
    }
    else {
        return $app;  # Production/test: no access log
    }

    # Set up filehandle
    my $fh;
    if ($log_dest eq '-') {
        $fh = \*STDOUT;  # stdout for access logs (like Uvicorn)
    } else {
        open $fh, '>>', $log_dest
            or die "Cannot open access log $log_dest: $!\n";
        $fh->autoflush(1);
    }

    require PAGI::Middleware::AccessLog;
    return PAGI::Middleware::AccessLog->new(logger => $fh)->wrap($app);
}
```

**3.2 Remove access_log from PAGI::Server**

- Delete `access_log` option from constructor
- Remove access log writes from request handling code
- No deprecation warning (BETA)

### Advanced Usage (in app code)

For Log::Any or custom logging, users configure in their app:

```perl
# app.pl
use PAGI::Middleware::AccessLog;

my $handler = sub { ... };

# Wrap with Log::Any-enabled access logging
my $app = AccessLog->new(
    logger   => 'Log::Any',
    category => 'myapp.access',
)->wrap($handler);

$app;  # Return wrapped app
```

Then run with `--no-access-log` to prevent double-logging:
```bash
pagi-server --no-access-log --app app.pl
# Or in production (no access log by default):
pagi-server -E production --app app.pl
```

## Part 4: Documentation

### 4.1 Add `=head1 LOGGING` to PAGI::Server POD

```pod
=head1 LOGGING

PAGI::Server logs operational messages (startup, shutdown, signals, worker
lifecycle, errors). By default these go to B<stderr> via Perl's C<warn()>.

B<Note:> Access logs (HTTP requests) are handled by L<PAGI::Middleware::AccessLog>
and go to B<stdout> by default. This separation follows Uvicorn's convention.

=head2 Using Log::Any

For production, route logs through L<Log::Any>:

    use Log::Any::Adapter ('Syslog', ident => 'pagi', facility => 'daemon');

    my $server = PAGI::Server->new(
        app    => $app,
        logger => 'Log::Any',
    );

=head2 Custom Logger

    my $server = PAGI::Server->new(
        app    => $app,
        logger => sub {
            my ($level, $message, $context) = @_;
            # Handle as needed
        },
    );

=head2 Performance Note

Default logging via C<warn()> is synchronous, consistent with Python ASGI
servers. For high-throughput production, consider Log::Any with an
async-capable adapter (syslog, fluent) or log to stderr and capture with
your container runtime.

=head2 Access Logs

For HTTP request/response logging, use L<PAGI::Middleware::AccessLog>:

    use PAGI::Middleware::AccessLog;

    my $app = AccessLog->new(logger => '/var/log/access.log')->wrap($handler);

Or via CLI:

    pagi-server --access-log /var/log/access.log --app app.pl

See L<PAGI::Runner/ADVANCED ACCESS LOGGING> for Log::Any and structured logging.
```

### 4.2 Add `=head1 ADVANCED ACCESS LOGGING` to PAGI::Runner POD

```pod
=head1 ADVANCED ACCESS LOGGING

The C<--access-log> option provides simple file-based access logging. For
advanced requirements like structured logging, syslog, or Log::Any integration,
configure access logging directly in your application.

=head2 Log Streams

Access logs go to B<stdout> by default (or to the file specified by
C<--access-log>). Server operational logs (startup, errors, signals) go to
B<stderr>. This follows Uvicorn's convention and works well with container
log drivers that separate the streams.

=head2 Performance Note

Access log writes are synchronous, consistent with how Uvicorn and Hypercorn
handle logging. For most deployments this is fine - log writes are small and
kernel-buffered.

For high-throughput production deployments, consider:

=over 4

=item * Log to stdout (C<--access-log ->) and let your container runtime
or log aggregator handle collection

=item * Use nginx as a reverse proxy and let nginx handle access logging

=item * Use Log::Any with an async-capable adapter (syslog, fluent, etc.)

=back

=head2 Using Log::Any for Access Logs

Configure L<Log::Any> in your app and wrap with L<PAGI::Middleware::AccessLog>:

    # app.pl
    use Log::Any::Adapter;
    use PAGI::Middleware::AccessLog;

    # Configure where access logs go
    Log::Any::Adapter->set(
        { category => 'MyApp::Access' },
        'File', '/var/log/myapp/access.log'
    );

    my $handler = sub {
        my ($scope, $receive, $send) = @_;
        # Your app logic
    };

    # Wrap with access logging
    my $app = AccessLog->new(
        logger   => 'Log::Any',
        category => 'MyApp::Access',
    )->wrap($handler);

    $app;  # Return the wrapped app

Then run B<without> C<--access-log> (your app handles it):

    pagi-server --app app.pl

=head2 JSON Structured Access Logs

    # app.pl
    use Log::Any::Adapter ('JSON', file => '/var/log/access.json');
    use PAGI::Middleware::AccessLog;

    my $app = AccessLog->new(
        logger   => 'Log::Any',
        category => 'MyApp::Access',
    )->wrap($handler);

Each request logs as a JSON object with fields: method, path, status,
duration_ms, client_ip, bytes, user_agent, referer.

=head2 Syslog Access Logs

    # app.pl
    use Log::Any::Adapter ('Syslog',
        ident    => 'myapp-access',
        facility => 'local0',
    );
    use PAGI::Middleware::AccessLog;

    my $app = AccessLog->new(
        logger   => 'Log::Any',
        category => 'MyApp::Access',
    )->wrap($handler);

=head2 Custom Access Log Callback

For complete control, provide a callback:

    # app.pl
    use PAGI::Middleware::AccessLog;

    my $app = AccessLog->new(
        logger => sub {
            my ($message, $context) = @_;
            # $message: formatted log line
            # $context: {
            #     method      => 'GET',
            #     path        => '/api/users',
            #     status      => 200,
            #     duration_ms => 45.2,
            #     client_ip   => '192.168.1.1',
            #     bytes       => 1234,
            #     user_agent  => 'Mozilla/5.0...',
            #     referer     => 'https://example.com',
            # }
            my $json = encode_json($context);
            print $my_custom_handle "$json\n";
        },
    )->wrap($handler);

=head2 Combining with CLI Options

You can use C<--access-log> for simple cases and configure advanced logging
in your app for other purposes. However, if your app wraps itself in
C<AccessLog> middleware, don't also use C<--access-log> or you'll get
duplicate logging.

=head2 Separate Server and Access Log Destinations

Server operational logs and access logs can use different backends:

    # app.pl
    use Log::Any::Adapter;
    use PAGI::Middleware::AccessLog;

    # Server logs -> syslog (configured when creating server)
    # Access logs -> file (configured here in app)
    Log::Any::Adapter->set(
        { category => 'MyApp::Access' },
        'File', '/var/log/access.log'
    );

    my $app = AccessLog->new(
        logger   => 'Log::Any',
        category => 'MyApp::Access',
    )->wrap($handler);

Then configure server logs separately:

    # In a wrapper script or use PAGI::Server directly
    use Log::Any::Adapter ('Syslog', ident => 'myapp');

    my $server = PAGI::Server->new(
        app    => $app,
        logger => 'Log::Any',  # Server logs to syslog
    );
```

### 4.3 Update PAGI::Middleware::AccessLog POD

```pod
=head1 NAME

PAGI::Middleware::AccessLog - HTTP request/response logging middleware

=head1 SYNOPSIS

    use PAGI::Middleware::AccessLog;

    # Simple: log to filehandle
    my $app = AccessLog->new(logger => \*STDERR)->wrap($handler);

    # Simple: log to file path
    my $app = AccessLog->new(logger => '/var/log/access.log')->wrap($handler);

    # Advanced: Log::Any integration
    use Log::Any::Adapter ('File', '/var/log/access.log');
    my $app = AccessLog->new(
        logger   => 'Log::Any',
        category => 'MyApp::Access',
    )->wrap($handler);

    # Advanced: custom callback with structured data
    my $app = AccessLog->new(
        logger => sub {
            my ($message, $context) = @_;
            # $context has: method, path, status, duration_ms, client_ip, bytes
        },
    )->wrap($handler);

=head1 DESCRIPTION

Logs HTTP requests in Apache combined log format (or custom formats).

=head1 OPTIONS

=over 4

=item logger => $destination

Where to send access log entries. Accepts:

=over 4

=item Filehandle (e.g., C<\*STDOUT>, C<\*STDERR>)

=item File path string (opened in append mode)

=item C<'Log::Any'> - route through L<Log::Any> (requires Log::Any installed)

=item Coderef - custom callback receiving C<($message, $context)>

=back

Default: C<\*STDOUT>

B<Why stdout?> Access logs are normal operational output, not errors.
This follows Uvicorn's convention and works well with container log drivers
that separate stdout/stderr streams. Server error logs go to stderr (via
C<warn()> or the C<logger> option on L<PAGI::Server>).

=item category => $string

Log::Any category name. Only used when C<logger => 'Log::Any'>.

Default: C<'PAGI::AccessLog'>

=item format => $format

Log format: C<'combined'> (default), C<'common'>, or C<'json'>.

=back

=head1 STRUCTURED CONTEXT

When using Log::Any or a custom callback, the C<$context> hashref contains:

    {
        method      => 'GET',
        path        => '/api/users',
        status      => 200,
        duration_ms => 45.2,
        client_ip   => '192.168.1.1',
        bytes       => 1234,
        user_agent  => 'Mozilla/5.0...',
        referer     => 'https://example.com',
        timestamp   => '2024-01-15T10:30:00Z',
    }

This enables structured logging backends (JSON, etc.) to index fields.

=head1 PERFORMANCE

Log writes are synchronous (blocking), consistent with Python ASGI servers
like Uvicorn and Hypercorn. This is typically fine - writes are small and
kernel-buffered.

For high-throughput scenarios, consider logging to stdout and using a
container log driver, or use Log::Any with an async-capable adapter
(syslog, fluent, etc.).

=head1 SEE ALSO

L<PAGI::Runner/ADVANCED ACCESS LOGGING> for configuration examples.
```

### 4.4 Add to cpanfile

```perl
recommends 'Log::Any' => '1.710';
```

## Testing

### Server Logging Tests (`t/server-logging.t`)

```perl
subtest 'default uses warn' => sub { ... };
subtest 'custom callback' => sub { ... };
subtest 'Log::Any integration' => sub { ... };
subtest 'worker propagation' => sub { ... };
```

### AccessLog Middleware Tests (`t/middleware-accesslog.t`)

```perl
subtest 'filehandle logging' => sub { ... };
subtest 'Log::Any logging' => sub { ... };
subtest 'custom callback' => sub { ... };
subtest 'structured context' => sub { ... };
```

### Runner Tests

```perl
subtest '--access-log wraps in middleware' => sub { ... };
subtest '--no-access-log skips middleware' => sub { ... };
```

## Migration Guide

### For Users

**Before (deprecated):**
```perl
my $server = PAGI::Server->new(
    app        => $app,
    access_log => $fh,
);
```

**After:**
```perl
use PAGI::Middleware::AccessLog;

my $app_with_logging = AccessLog->new(logger => $fh)->wrap($app);

my $server = PAGI::Server->new(
    app => $app_with_logging,
);
```

**Or via CLI (unchanged):**
```bash
pagi-server --access-log /var/log/access.log --app app.pl
```

## Estimated Effort

| Task | Time |
|------|------|
| Part 1: Server logger option | 1.5 hours |
| Part 2: AccessLog middleware enhancement | 1.5 hours |
| Part 3: Runner updates (middleware wrapping, remove --no-access-log) | 45 min |
| Part 4.1: PAGI::Server LOGGING POD | 20 min |
| Part 4.2: PAGI::Runner ADVANCED ACCESS LOGGING POD | 30 min |
| Part 4.3: PAGI::Middleware::AccessLog POD | 30 min |
| Part 4.4: cpanfile update | 5 min |
| Testing | 1 hour |
| **Total** | **~6 hours** |

## Dependencies

- **Required:** None (default behavior needs nothing)
- **Optional:** Log::Any >= 1.710

## Backward Compatibility

**No breaking CLI changes** - environment-based defaults already exist.

**Internal changes (transparent to users):**

- Access logging now uses middleware instead of Server option
- `PAGI::Server` `access_log` option removed (BETA, no warning needed)

**CLI behavior unchanged:**

- Development mode: access log to STDERR by default
- Production mode: no access log by default
- `--access-log FILE` works same as before
- `--no-access-log` works same as before

## Relationship to Metrics::Any Plan

Both follow the same pattern:
- Optional dependency
- Explicit opt-in
- Graceful degradation when module not installed
- Middleware for request-level concerns, Server for operational concerns
