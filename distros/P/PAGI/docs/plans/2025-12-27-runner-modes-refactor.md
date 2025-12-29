# PAGI::Runner Refactor: Modes and Server-Agnostic Design

**Date:** 2025-12-27
**Status:** Planned
**Breaking Change:** Yes (programmatic Runner usage)

## Problem Statement

PAGI::Runner currently:
- Duplicates/mirrors PAGI::Server options explicitly
- Every new server option requires updating Runner
- No concept of run modes (development vs production)
- No auto-middleware for development convenience
- Tightly coupled to PAGI::Server's API

## Goals

1. Make PAGI::Runner server-agnostic (like Plack::Runner)
2. Add run modes with auto-detection (development/production)
3. Use flag pass-through for server-specific options
4. Keep CLI interface unchanged for users
5. Enable future pluggable server backends

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    pagi-server                          │
│         (thin wrapper, like plackup)                    │
│         PAGI::Runner->run(@ARGV)                        │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│                   PAGI::Runner                          │
│  - App loading (files, modules, default)                │
│  - Common flags (host, port, daemonize, etc.)           │
│  - Mode detection and middleware wrapping               │
│  - Pass-through for server-specific flags               │
│  - Server creation and lifecycle                        │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│                   PAGI::Server                          │
│  (or future: any PAGI-compatible server via -s flag)   │
└─────────────────────────────────────────────────────────┘
```

## Run Modes

### Environment Variable

`PAGI_ENV` - Takes precedence over auto-detection.

### CLI Flag

`-E` or `--env` - Explicit mode selection.

### Auto-Detection (Default)

```perl
sub mode {
    my ($self) = @_;
    return $self->{env} if defined $self->{env};
    return $ENV{PAGI_ENV} if defined $ENV{PAGI_ENV};
    return -t STDIN ? 'development' : 'production';
}
```

- TTY detected (interactive terminal) → `development`
- No TTY (systemd, docker, cron) → `production`

### Standard Modes

| Mode | Behavior |
|------|----------|
| `development` | Auto-enable Lint middleware (strict mode) |
| `production` | No auto-middleware, safe defaults |
| `none` | Explicit opt-out, no auto-middleware |

### Usage Examples

```bash
# Auto-detect (TTY = development, else production)
pagi-server app.pl

# Explicit modes
pagi-server -E development app.pl
pagi-server -E production app.pl
pagi-server -E none app.pl

# Environment variable
PAGI_ENV=production pagi-server app.pl

# Disable auto-middleware in dev mode
pagi-server --no-default-middleware app.pl
```

### Development Mode Middleware

Initially, development mode enables:

1. `PAGI::Middleware::Lint` with `strict => 1` - Catches spec violations

Future additions (not in this plan):
- Debug middleware (stack traces in browser)
- Verbose error responses

## Flag Organization

### Runner Flags (Common to All Servers)

| Flag | Description |
|------|-------------|
| `-a`, `--app` | Application file (legacy) |
| `-h`, `--host` | Bind host (default: 127.0.0.1) |
| `-p`, `--port` | Bind port (default: 5000) |
| `-s`, `--server` | Server class (future, default: PAGI::Server) |
| `-E`, `--env` | Environment mode |
| `-I`, `--lib` | Add to @INC (repeatable) |
| `-D`, `--daemonize` | Run as daemon |
| `--access-log` | Access log path |
| `--no-access-log` | Disable access logging |
| `--pid` | PID file path |
| `--user`, `--group` | Drop privileges |
| `-q`, `--quiet` | Suppress output |
| `--loop` | IO::Async::Loop backend |
| `--default-middleware` | Toggle mode middleware (default: on) |
| `--help`, `--version` | Help/version |

### PAGI::Server-Specific Flags (Pass-Through)

| Flag | Default | Description |
|------|---------|-------------|
| `-w`, `--workers` | 0 | Worker processes |
| `--reuseport` | 0 | SO_REUSEPORT mode |
| `--max-requests` | 0 | Requests per worker before restart |
| `--max-connections` | 0 | Max concurrent connections |
| `--ssl-cert` | - | SSL certificate file |
| `--ssl-key` | - | SSL private key file |
| `--timeout` | 60 | Connection idle timeout |
| `--shutdown-timeout` | 30 | Graceful shutdown timeout |
| `--request-timeout` | 0 | Request stall timeout |
| `--ws-idle-timeout` | 0 | WebSocket idle timeout |
| `--sse-idle-timeout` | 0 | SSE idle timeout |
| `--max-body-size` | 10MB | Max request body |
| `--max-header-size` | 8192 | Max header size |
| `--max-header-count` | 100 | Max number of headers |
| `--max-receive-queue` | 1000 | WebSocket receive queue |
| `--max-ws-frame-size` | 64KB | WebSocket frame size |
| `-b`, `--listener-backlog` | 2048 | Listen queue size |
| `--log-level` | info | Log verbosity |
| `--sync-file-threshold` | 64KB | Sync file read threshold |

## Implementation

### pagi-server (Thin Wrapper)

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use PAGI::Runner;

PAGI::Runner->run(@ARGV);
```

### PAGI::Runner Core Methods

```perl
package PAGI::Runner;

sub run {
    my $class = shift;
    my $self = ref $class ? $class : $class->new;
    $self->parse_options(@_);
    $self->run_loop;
}

sub parse_options {
    my ($self, @args) = @_;

    # Getopt with pass_through
    GetOptionsFromArray(\@args,
        'a|app=s'             => \$self->{app},
        'o|host=s'            => \$self->{host},
        'p|port=i'            => \$self->{port},
        's|server=s'          => \$self->{server},
        'E|env=s'             => \$self->{env},
        'I=s@'                => \$self->{includes},
        'D|daemonize'         => \$self->{daemonize},
        'access-log=s'        => \$self->{access_log},
        'no-access-log'       => \$self->{no_access_log},
        'pid=s'               => \$self->{pid_file},
        'user=s'              => \$self->{user},
        'group=s'             => \$self->{group},
        'q|quiet'             => \$self->{quiet},
        'l|loop=s'            => \$self->{loop},
        'default-middleware!' => \$self->{default_middleware},
        'help'                => \$self->{help},
        'version'             => \$self->{version},
    );

    # Separate server options from app spec
    for my $arg (@args) {
        if ($arg =~ /^-/) {
            push @{$self->{server_options}}, $arg;
        } else {
            push @{$self->{argv}}, $arg;
        }
    }
}

sub mode {
    my ($self) = @_;
    return $self->{env} if defined $self->{env};
    return $ENV{PAGI_ENV} if defined $ENV{PAGI_ENV};
    return -t STDIN ? 'development' : 'production';
}

sub prepare_app {
    my ($self) = @_;
    my $app = $self->load_app;

    # Wrap with mode middleware
    if ($self->mode eq 'development' && ($self->{default_middleware} // 1)) {
        require PAGI::Middleware::Lint;
        $app = PAGI::Middleware::Lint->new(strict => 1)->wrap($app);
    }

    return $app;
}

sub load_server {
    my ($self) = @_;

    my $server_class = $self->{server} // 'PAGI::Server';
    eval "require $server_class" or die "Cannot load $server_class: $@\n";

    my %opts = $self->_parse_server_options($server_class);

    # Handle access log
    my $access_log;
    if ($self->{no_access_log}) {
        $access_log = undef;
    } elsif ($self->{access_log}) {
        open $access_log, '>>', $self->{access_log}
            or die "Cannot open access log: $!\n";
    }

    return $server_class->new(
        app        => $self->prepare_app,
        host       => $self->{host} // '127.0.0.1',
        port       => $self->{port} // 5000,
        quiet      => $self->{quiet} // 0,
        access_log => $access_log,
        %opts,
    );
}

sub _parse_server_options {
    my ($self, $server_class) = @_;

    my @args = @{$self->{server_options} // []};
    my %opts;

    if ($server_class eq 'PAGI::Server') {
        GetOptionsFromArray(\@args,
            # Workers/scaling
            'w|workers=i'           => \$opts{workers},
            'reuseport'             => \$opts{reuseport},
            'max-requests=i'        => \$opts{max_requests},
            'max-connections=i'     => \$opts{max_connections},

            # TLS
            'ssl-cert=s'            => \$opts{_ssl_cert},
            'ssl-key=s'             => \$opts{_ssl_key},

            # Timeouts
            'timeout=i'             => \$opts{timeout},
            'shutdown-timeout=i'    => \$opts{shutdown_timeout},
            'request-timeout=i'     => \$opts{request_timeout},
            'ws-idle-timeout=i'     => \$opts{ws_idle_timeout},
            'sse-idle-timeout=i'    => \$opts{sse_idle_timeout},

            # Limits
            'max-body-size=i'       => \$opts{max_body_size},
            'max-header-size=i'     => \$opts{max_header_size},
            'max-header-count=i'    => \$opts{max_header_count},
            'max-receive-queue=i'   => \$opts{max_receive_queue},
            'max-ws-frame-size=i'   => \$opts{max_ws_frame_size},
            'listener-backlog|b=i'  => \$opts{listener_backlog},

            # Misc
            'log-level=s'           => \$opts{log_level},
            'sync-file-threshold=i' => \$opts{sync_file_threshold},
        );

        # Build ssl hash if certs provided
        if ($opts{_ssl_cert} && $opts{_ssl_key}) {
            $opts{ssl} = {
                cert_file => delete $opts{_ssl_cert},
                key_file  => delete $opts{_ssl_key},
            };
        }
        delete $opts{_ssl_cert};
        delete $opts{_ssl_key};
    }

    return map { $_ => $opts{$_} } grep { defined $opts{$_} } keys %opts;
}

sub run_loop {
    my ($self) = @_;

    return $self->_show_help if $self->{help};
    return $self->_show_version if $self->{version};

    # Add library paths
    unshift @INC, @{$self->{includes}} if $self->{includes};

    my $server = $self->load_server;
    my $loop = $self->_create_loop;

    $loop->add($server);
    $server->listen->get;

    # Post-bind operations
    $self->_daemonize if $self->{daemonize};
    $self->_write_pid_file if $self->{pid_file};
    $self->_drop_privileges if $self->{user} || $self->{group};

    $loop->run;
}
```

## Breaking Changes

### Programmatic Usage

```perl
# OLD (0.x) - No longer works
my $runner = PAGI::Runner->new(workers => 4, reuseport => 1);
$runner->parse_options(@ARGV);
$runner->run;

# NEW (1.x)
use PAGI::Runner;
PAGI::Runner->run(@ARGV);

# Or for more control:
my $runner = PAGI::Runner->new;
$runner->parse_options(@ARGV, '--workers', '4', '--reuseport');
$runner->run_loop;
```

### CLI Interface

**No changes** - All existing CLI usage continues to work:

```bash
pagi-server --workers 4 --reuseport ./app.pl
pagi-server -p 8080 PAGI::App::Directory root=/var/www
```

### New Behavior

- Development mode auto-detected when running in terminal
- Lint middleware auto-enabled in development mode
- Use `--no-default-middleware` or `-E production` to disable

## Implementation Steps

### Phase 1: PAGI::Runner Refactor

1. Refactor `parse_options()` to use pass_through
2. Add `mode()` method with TTY auto-detection
3. Add `wrap_for_mode()` for Lint middleware
4. Add `--default-middleware` flag
5. Refactor `run()` as main entry point
6. Add `_parse_server_options()` for PAGI::Server flags
7. Keep `--loop` in Runner (IO::Async, not server-specific)

### Phase 2: pagi-server Simplification

1. Replace with thin wrapper
2. Update POD to document all flags

### Phase 3: Tests

1. Test mode detection (TTY vs non-TTY, explicit `-E`)
2. Test Lint auto-wrapping in development mode
3. Test `--no-default-middleware` disables wrapping
4. Test pass-through of server-specific flags

### Phase 4: Documentation

1. Update PAGI::Runner POD
2. Update pagi-server POD
3. Update CHANGES
4. Add migration notes

## Future Work (TODO)

These are out of scope for this plan but should be added to TODO.md:

1. **bin/pagi-runner** - Generic runner with `-s` flag for pluggable servers
2. **Auto-reload loader** - Like Plack::Loader::Restarter for development
3. **Debug middleware** - Stack traces in browser for development mode
4. **Shotgun loader** - Fork-per-request for development

## Testing Checklist

- [ ] Mode detection: TTY returns 'development'
- [ ] Mode detection: Non-TTY returns 'production'
- [ ] Mode detection: `-E production` overrides TTY
- [ ] Mode detection: `PAGI_ENV` takes precedence
- [ ] Lint middleware applied in development mode
- [ ] Lint middleware NOT applied in production mode
- [ ] `--no-default-middleware` disables Lint
- [ ] All PAGI::Server flags pass through correctly
- [ ] SSL cert/key combined into ssl hash
- [ ] Existing CLI usage unchanged
- [ ] App loading works (file, module, default)
- [ ] Daemonize, PID file, privileges still work
