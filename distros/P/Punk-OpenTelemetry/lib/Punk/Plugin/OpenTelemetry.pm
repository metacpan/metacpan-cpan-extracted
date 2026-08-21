package Punk::Plugin::OpenTelemetry;

use 5.010;
use strict;
use warnings;
use Carp ();
use Punk::OpenTelemetry ();

our $VERSION = '0.04';

my %STATE;

sub _state { $STATE{ $_[0] } //= { declared => {}, installed => 0 } }
sub state_for { $STATE{ $_[1] // $_[0] } }   # a test and introspection seam

sub import {
    my ($class) = @_;
    my $caller = caller;
    _install_keywords($caller);
    return;
}

sub _install_keywords {
    my ($pkg, $app) = @_;
    my $st = _state($pkg);
    return if $st->{keywords_installed};

    $app ||= $pkg->can('punk_app') ? $pkg->punk_app
        : Carp::croak("Punk::Plugin::OpenTelemetry: $pkg is not a Punk "
                    . "application - `use Punk` before "
                    . "`use Punk::Plugin::OpenTelemetry`");
    $st->{keywords_installed} = 1;

    $app->install_kw(otel => sub {
        my (%opt) = @_;
        return $st->{tracer} if !%opt && $st->{tracer};
        @{ $st->{declared} }{ keys %opt } = values %opt;
        return;
    }, __PACKAGE__);
    return;
}

sub new { bless {}, $_[0] }

sub register {
    my ($self, $app, $opts) = @_;
    $opts //= {};
    my $pkg = $app->caller_class
        or Carp::croak('Punk::Plugin::OpenTelemetry: the app has no caller class');
    my $st = _state($pkg);
    _install_keywords($pkg, $app);
    $st->{app}  = $app;
    $st->{opts} = $opts;
    
    $app->hook(after_dispatch => sub {
        _tick($st) if $st->{built} && !$st->{disabled};
        return;
    });

    $app->middleware(sub {
        my ($inner) = @_;
        _build($st) unless $st->{built};
        return $inner;
    });

    $app->helper(otel       => sub { $st->{tracer} }, __PACKAGE__);
    $app->helper(otel_meter => sub { $st->{meter}  }, __PACKAGE__);
    return;
}

sub _build {
    my ($st) = @_;
    $st->{built} = 1;
    my $app  = $st->{app};
    my $opts = $st->{opts} || {};

    my $cfg = $st->{config} = _resolve($app, $st, $opts);

    if (Punk::OpenTelemetry::Config::disabled($cfg)) {
        $st->{disabled} = 1;
        _diagnostic($app, $cfg);
        return;
    }

    my $resource = Punk::OpenTelemetry::Resource::detect(
        (defined $cfg->{service_name}
            ? (service_name => $cfg->{service_name}) : ()),
        %{ $cfg->{resource_attributes} || {} },
    );

    my ($sampler, $ratio) = _sampler($cfg);
    my $tracer = $st->{tracer} = Punk::OpenTelemetry::Tracer->new(
        resource         => $resource,
        scope_name       => 'Punk::OpenTelemetry',
        scope_version    => $Punk::OpenTelemetry::VERSION,
        schema_url       => Punk::OpenTelemetry::Instrument::schema_url(),
        scope_schema_url => Punk::OpenTelemetry::Instrument::schema_url(),
        sampler          => $sampler,
        ratio            => $ratio,
    );

    $st->{exporter} = Punk::OpenTelemetry::Exporter->new(
        (defined $cfg->{endpoint}    ? (endpoint    => $cfg->{endpoint})    : ()),
        (defined $cfg->{endpoints}   ? (endpoints   => $cfg->{endpoints})   : ()),
        (defined $cfg->{protocol}    ? (protocol    => $cfg->{protocol})    : ()),
        (defined $cfg->{headers}     ? (headers     => $cfg->{headers})     : ()),
        (defined $cfg->{compression} ? (compression => $cfg->{compression}) : ()),
        (defined $cfg->{timeout} ? (timeout => $cfg->{timeout} / 1000) : ()),
        (defined $cfg->{ua} ? (ua => $cfg->{ua}) : ()),
    );

    $st->{meter} = Punk::OpenTelemetry::Meter->new(
        resource    => $resource,
        scope_name  => 'Punk::OpenTelemetry',
        temporality => $cfg->{temporality_preference} || 'cumulative',
    ) if _want($cfg, 'metrics');

    $st->{logs} = Punk::OpenTelemetry::Logs->new(
        resource   => $resource,
        scope_name => 'Punk::OpenTelemetry',
    ) if _want($cfg, 'logs');

    $st->{points} = Punk::OpenTelemetry::Instrument::install($tracer,
        server => _want($cfg, 'server'),
        client => _want($cfg, 'client'),
        db     => _want($cfg, 'db'),
    );
    $st->{installed} = 1;

    _on_worker_start(sub {
        $tracer->resource_attr('service.instance.id',
                               Punk::OpenTelemetry::Resource::instance_id());
    });

    _diagnostic($app, $cfg);
    return;
}

sub _join_loop {
    my ($st) = @_;
    $st->{joined} = 1;
    my $cfg = $st->{config} || {};
    return if $cfg->{ua} || !$st->{exporter};
    return unless $INC{'Hyperman.pm'} && eval { require Fetch; 1 };
    my $loop = eval { Hyperman->loop } or return;
    my $ua = eval {
        Fetch->new(loop => $loop, timeout => $st->{exporter}{timeout})
    } or return;
    $st->{exporter}{ua} = $ua;
    return 1;
}

sub _start_processor {
    my ($st) = @_;
    return $st->{processor} if $st->{processor};
    my $cfg   = $st->{config};
    my $delay = ($cfg->{bsp}{schedule_delay} || 5000) / 1000;

    my $tick;
    $tick = sub {
        flush($st);
        $st->{exporter}->_sleep($delay, $tick)
            if ($st->{processor} || '') eq 'timer';
    };

    my $loop = eval { $st->{exporter}{ua}->loop };
    if ($loop && eval { $loop->can('_ft_timer') }) {
        $st->{processor} = 'timer';
        $st->{exporter}->_sleep($delay, sub { $tick->() });
    }
    else { $st->{processor} = 'per-request' }
    return $st->{processor};
}

sub _tick {
    my ($st) = @_;
    my $t = $st->{tracer} or return;

    delete $st->{processor} if !$st->{joined} && _join_loop($st);
    _start_processor($st) unless $st->{processor};

    return if ($st->{processor} || '') eq 'timer';   # the timer has it

    my $cfg   = $st->{config};
    my $batch = $cfg->{bsp}{max_export_batch_size} || 512;
    my $delay = ($cfg->{bsp}{schedule_delay} || 5000) / 1000;
    $st->{last_flush} ||= time;
    return if $t->queued < $batch && time - $st->{last_flush} < $delay;
    $st->{last_flush} = time;
    flush($st);
    return;
}

sub flush {
    my ($st) = @_;
    return unless $st->{exporter};
    eval {
        if (my $t = $st->{tracer}) { my $p = $t->drain;   _send($st, traces  => $p) if $p }
        if (my $m = $st->{meter})  { my $p = $m->collect; _send($st, metrics => $p) if $p }
        if (my $l = $st->{logs})   { my $p = $l->drain;   _send($st, logs    => $p) if $p }
        1;
    } or do { $st->{exporter}{stats}{failures}++ };
    return;
}

sub _send {
    my ($st, $signal, $payload, $attempt) = @_;
    $attempt //= 0;
    my $exp   = $st->{exporter};
    my $stats = $exp->{stats};

    Punk::OpenTelemetry::Instrument::suppress_begin();
    my ($bytes, $f);
    my $ok = eval {
        $bytes = $exp->encode($signal => $payload);
        $f     = $exp->_attempt($signal, $bytes);
        1;
    };
    my $err = $@;
    Punk::OpenTelemetry::Instrument::suppress_end();
    die $err if !$ok;
    return unless $f;

    $f->on_ready(sub {
        my ($fut) = @_;
        my $res = eval { $fut->get };
        my ($verdict, $after) = $res
            ? $exp->_classify($res->status, $res->headers, $res->content)
            : $exp->_classify(undef);

        if    ($verdict eq 'ok')      { $stats->{exported}++ }
        elsif ($verdict eq 'partial') { $stats->{exported}++; $stats->{partial}++ }
        elsif ($verdict eq 'permanent') {
            $stats->{rejected}++;
            $stats->{dropped}++;
        }
        elsif ($attempt >= ($exp->{max_retries} // 5)) {
            $stats->{failures}++;
            $stats->{dropped}++;
        }
        else {
            $stats->{retries}++;
            my $wait = $exp->backoff($attempt + 1, $after);
            $exp->_sleep($wait, sub { _send($st, $signal, $payload, $attempt + 1) });
        }
        return;
    });
    return;
}

sub _resolve {
    my ($app, $st, $opts) = @_;

    my %kw = (%{ $st->{declared} || {} }, %$opts);

    my $file;
    if (my $cfg = eval { $app->config }) {
        $file = $cfg->{otel} if ref $cfg eq 'HASH' && ref $cfg->{otel} eq 'HASH';
    }

    return Punk::OpenTelemetry::Config::resolve(
        \%kw, $file, Punk::OpenTelemetry::Config::from_env());
}


sub _sampler {
    my ($cfg) = @_;
    my $name  = $cfg->{sampler} // 'parentbased_always_on';
    my $arg   = $cfg->{sampler_arg};
    my $ratio = defined $arg && $arg =~ /^[0-9.]+$/ ? $arg + 0 : 1.0;

    return ('always_off', $ratio)
        if $name eq 'always_off' || $name eq 'parentbased_always_off';
    return ('always_on', $ratio)
        if $name eq 'always_on';
    return ('parent_ratio', $ratio);
}

sub _want {
    my ($cfg, $what) = @_;
    return 1 unless exists $cfg->{$what};
    return $cfg->{$what} ? 1 : 0;
}

sub _diagnostic {
    my ($app, $cfg) = @_;
    my $line = Punk::OpenTelemetry::Config::diagnostic($cfg);
    my $log  = eval { $app->can('log') ? $app->log : undef };
    if ($log && $log->can('info')) { $log->info($line) }
    else { warn "$line\n" }
    return $line;
}

sub _on_worker_start {
    my ($cb) = @_;
    return 0 unless $INC{'Hyperman.pm'} && Hyperman->can('on_worker_start');
    Hyperman->on_worker_start($cb);
    return 1;
}

1;

__END__

=head1 NAME

Punk::Plugin::OpenTelemetry - OpenTelemetry for a Punk application

=head1 SYNOPSIS

    package MyApp;
    use Punk;
    use Punk::Plugin::OpenTelemetry;

    otel service_name => 'checkout',
         endpoint     => 'http://collector:4318';

    plugin 'OpenTelemetry';

    get '/orders/:id' => sub {
        my ($c) = @_;
        $c->otel;                     # the tracer
        $c->json({ ok => 1 });
    };

Or entirely from the environment, with no code at all:

    OTEL_SERVICE_NAME=checkout \
    OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4318 \
    plackup -s Hyperman app.psgi

=head1 DESCRIPTION

Registering this plugin turns on server, client and database spans, the
metrics the HTTP conventions ask for, and log records correlated by trace id.
The instrumentation goes through C ABI observer tables in Punk, Fetch and
DBIx::Loop, so an instrumented request pays no Perl frame for being
instrumented, and an unsampled one allocates nothing at all.

=head1 CONFIGURATION

Three sources, in this order:

    otel keyword  >  punk.yml otel: block  >  OTEL_* environment  >  default

The specification defines three configuration interfaces - programmatic,
environment variable and declarative file - and says programmatic
configuration is the foundation the others should be built on. It states no
precedence between programmatic and environment configuration, and gives
exactly one precedence rule: a declarative config file takes precedence over
the SDK configuration environment variables. The order above matches the spec
where it speaks and follows its stated principle where it does not. It is also
Punk's own convention, which layers F<punk.yml> under what the app class
declared.

The F<punk.yml> C<otel:> block is B<not> the spec's declarative configuration
format, and the two should not be conflated. Supporting
C<OTEL_EXPERIMENTAL_CONFIG_FILE> is separate work; were it added, that file
would take precedence over the C<OTEL_*> variables as the spec requires, and
would sit between the C<punk.yml> block and the environment.

    # punk.yml
    otel:
      service_name: checkout
      endpoint: http://collector:4318
      sampler: traceidratio
      sampler_arg: 0.05

=head2 With no endpoint, nothing is exported

There is B<no default endpoint>. Set none and the SDK builds, instruments the
request path, records spans and then has nowhere to send them - so they are
dropped. It does not fall back to C<http://localhost:4318>.

This is worth stating plainly because other SDKs do default to that address,
and because the failure is silent: the application works, the boot line says
C<enabled>, and no telemetry ever arrives. If you have configured everything
else and are seeing nothing, check the endpoint first.

    OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318      # a local collector

=head2 The environment

The C<OTEL_*> variables are read by
L<Punk::OpenTelemetry::Config/from_env>, once, at boot. Re-reading C<%ENV> per
request would be both slower and wrong: a worker that picked up a mid-flight
change would disagree with its siblings, and telemetry that disagrees about
its own configuration is worse than telemetry that is uniformly stale.

=head2 Turning it off

C<OTEL_SDK_DISABLED=true> is checked before anything is built and before a
single hook is registered. Nothing is allocated, the request path is not
wrapped, and the process is not paying for telemetry it is not sending.

The value is the spec's boolean, not Perl truth: only the string C<true>,
case-insensitively, disables the SDK. C<OTEL_SDK_DISABLED=false> does not, and
it would under any looser rule.

=head2 Credentials

C<OTEL_EXPORTER_OTLP_HEADERS> carries the token the exporter authenticates
with. Header values are never printed in the boot diagnostic, never written to
a span attribute and never included in a self-diagnostic. The diagnostic
prints the header B<count>, because "did my credentials arrive" is a real
question and a number answers it without answering anything else.

=head1 THE BOOT DIAGNOSTIC

One line at info, stating whether it is enabled, the service name, the
protocol, the endpoint, the sampler and its argument, and the propagators.
Almost every OpenTelemetry support question is answered by those six facts,
and almost no SDK prints them.

    OpenTelemetry enabled service=checkout protocol=http/protobuf
    endpoint=http://collector:4318 sampler=traceidratio:0.05
    propagators=tracecontext,baggage

=head1 THE FORK TRAP

The resource is built at boot, in the parent, and every attribute on it is
inherited by every worker - which is right for all of them except one.
C<service.instance.id> must differ per worker, so each takes a fresh one from
L<Hyperman>'s C<on_worker_start>.

This is the single most common way a home-grown metrics layer is broken, and
it is invisible: a collector receiving several workers' cumulative series
under one identity does not report a conflict, it resolves it, and the numbers
come out wrong by a factor of however many workers are running.

=head1 KEYWORDS

=head2 otel %opt

Records configuration. Declaring it more than once merges, so a base class can
set the service name and a subclass add the endpoint. It may be called before
or after C<plugin 'OpenTelemetry'>, since the keyword is installed by C<use>.

Called with no arguments it returns the tracer - but only once the application
has been built, because that is when the configuration is resolved and the
tracer constructed. Before C<to_app> it returns C<undef>. In a route handler
it is always there; at application-body scope it is not, and C<< $c->otel >>
is the accessor to reach for anyway.

=head1 HELPERS

=head2 $c->otel

The tracer.

=head2 $c->otel_meter

The meter, when the metrics signal is on.

=head1 SEE ALSO

L<Punk::OpenTelemetry>, L<Punk::OpenTelemetry::Config>,
L<Punk::OpenTelemetry::Instrument>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
