package Punk::Plugin::OpenTelemetry;

use 5.010;
use strict;
use warnings;
use Carp ();
use Punk::OpenTelemetry ();

our $VERSION = '0.10';

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
    $app->helper(otel_logs  => sub { $st->{logs}   }, __PACKAGE__);
    $app->helper(otel_span  => sub { _current_span($_[0]) }, __PACKAGE__);

    return;
}

# The server span for this request, as `emit` takes one.
#
# READ AND NEVER TAKEN. The response side unstashes the span to end it, and
# unstashing CLEARS the slot - so a helper that used the same call would end
# the request's span by looking at it, and the trace would lose its root.
sub _current_span {
    my ($c) = @_;
    my $stash = eval { $c->stash } or return undef;
    my $ptr = $stash->{'punk.otel.span'};
    # Zero is the response side saying it has already taken the span. A record
    # emitted after the span ended is correlated with nothing rather than with
    # freed memory.
    return undef unless defined $ptr && $ptr =~ /\A\d+\z/ && $ptr > 0;

    # BORROWED, and blessed into the class that cannot free it. The same
    # pointer in a Punk::OpenTelemetry::Span would be freed when this handle
    # went out of scope, and the response side would then end a span that had
    # already gone back to the allocator.
    return bless \$ptr, 'Punk::OpenTelemetry::SpanRef';
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

    # THE APPLICATION'S OWN LOGGER IS THE LOGS SIGNAL.
    #
    # `$c->log->error(...)` is the whole interface. Punk hands this a copy of
    # every record it emits and the context it was emitted against, and the
    # copy leaves here with the request's trace id on it.
    #
    # A tap and not a sink: the line still goes wherever it was going, so
    # turning telemetry on never takes an operator's logs away and a collector
    # outage never silences them.
    Punk::OpenTelemetry::Logs::install_tap($st->{logs});

    # THE METER GOES IN TOO, so the instrumentation can record the HTTP
    # duration histogram itself. Handed the object rather than a flag: without
    # it the instrumentation records nothing and does not even start the
    # clock, so a deployment with metrics off pays nothing.
    $st->{points} = Punk::OpenTelemetry::Instrument::install($tracer,
        server  => _want($cfg, 'server'),
        client  => _want($cfg, 'client'),
        db      => _want($cfg, 'db'),
        metrics => _want($cfg, 'metrics'),
        ($st->{meter} ? (meter => $st->{meter}) : ()),
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

    # ONE EVAL PER SIGNAL, not one around all three.
    #
    # A single eval means the first signal that throws takes the other two
    # with it - and the drain that never ran leaves its records queued, so
    # they are not even lost loudly. That is how metrics failing to encode
    # silently stopped logs from being exported at all: two signals gone to
    # one broken encoder, with nothing in the output to say so.
    eval { if (my $t = $st->{tracer}) { my $p = $t->drain;   _send($st, traces  => $p) if $p } 1 }
        or do { $st->{exporter}{stats}{failures}++ };
    eval { if (my $m = $st->{meter})  { my $p = $m->collect; _send($st, metrics => $p) if $p } 1 }
        or do { $st->{exporter}{stats}{failures}++ };
    eval { if (my $l = $st->{logs})   { my $p = $l->drain;   _send($st, logs    => $p) if $p } 1 }
        or do { $st->{exporter}{stats}{failures}++ };
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

    # SUPPRESSED, because the log tap is live by now and this is the SDK
    # talking about itself. Everything the SDK does on its own behalf runs
    # inside the guard - otherwise its own boot line becomes a log record,
    # which becomes an export, and its own report of a failed export becomes
    # another one.
    #
    # The operator still gets the line. It goes to the log exactly as before;
    # it just is not also telemetry about the telemetry.
    Punk::OpenTelemetry::Instrument::suppress_begin();
    if ($log && $log->can('info')) { eval { $log->info($line) } }
    else { warn "$line\n" }
    Punk::OpenTelemetry::Instrument::suppress_end();
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

Registering this plugin turns on server, client and database spans,
C<http.server.request.duration>, and log records correlated by trace id.

=head2 The one metric, and why it is not sampled

C<http.server.request.duration> is recorded on B<every> request, including the
ones no span was built for. A trace at 5% is a sample of requests; a duration
histogram at 5% is a wrong number, so the two signals cannot share a sampling
decision. What an unsampled request pays is two integers into the stash the
dispatcher had already built.

Its attributes are C<http.request.method> (canonical, C<_OTHER> for anything
else), C<http.response.status_code>, and C<http.route> - the declared pattern,
and B<absent> when there is none. Never C<url.path>: on a metric that
substitution turns a scanner's million 404 paths into a million series, and the
cardinality cap then starts dropping whatever arrives next.

The boundaries are the conventions' own, in seconds. Everything else the meter
records is the application's, through C<< $c->otel_meter >>.
The instrumentation goes through C ABI observer tables in Punk, Fetch and
DBIx::Loop, so an instrumented request pays no Perl frame for being
instrumented, and an unsampled one allocates nothing at all.

One exception, and it is Punk's: from Punk 0.50 the shipped DBI model backend
takes a handle subclass when a query observer is registered, so that statements
run through C<< $model->backend->dbh >> are seen and not only the six generated
methods. That subclass is a sub call per statement, paid only by an application
that asked to see its statements. See L<Punk::Model::DBI>.

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
protocol, the endpoint, and the sampler with its argument. Almost every
OpenTelemetry support question is answered by those five facts, and almost no
SDK prints them.

    OpenTelemetry enabled service=checkout protocol=http/protobuf
    endpoint=http://collector:4318 sampler=traceidratio:0.05

The configured propagators are B<not> in this line. Printing a setting here
says it does something, and C<OTEL_PROPAGATORS> does not reach the automatic
instrumentation - see L</PROPAGATION IS W3C ONLY>.

=head1 PROPAGATION IS W3C ONLY

The automatic instrumentation reads one inbound header, C<traceparent>, and
injects one outbound, C<traceparent>. That is the whole of it, whatever
C<OTEL_PROPAGATORS> is set to.

B3, Jaeger and Baggage are implemented, tested and reachable - through
L<Punk::OpenTelemetry::Propagate>'s C<extract> and C<inject> - for a caller
doing it by hand. No instrumentation point consults them.

C<OTEL_PROPAGATORS> is therefore parsed, validated and stored, and then has no
effect. That is worth knowing before an afternoon is spent wondering why a B3
header never joined a trace up, which is why this section exists rather than
the setting being quietly dropped.

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

=head2 $c->otel_logs

The logger, when the logs signal is on.

=head2 $c->otel_span

The request's own server span, in the form C<< $logger->emit >> and
C<< $meter->record >> take one, or C<undef> when there is none - before the
span starts, after it ends, or when the request was not sampled.

Pass it to C<record> to attach an exemplar: an exemplar is the trace id on a
point of a histogram, and it is what turns "the p99 got worse" into the
specific request that made it worse.

=head1 THE LOGS SIGNAL IS YOUR OWN LOGGER

There is no separate call. C<< $c->log->error(...) >> is the whole interface:
Punk hands this plugin a copy of every record its logger emits, together with
the context it was emitted against, and the copy is exported carrying that
request's trace id.

    $c->log->error('card refused');
    $c->log->error({ message => 'card refused',
                     'payment.reason' => 'insufficient_funds' });

A record's fields become the log record's attributes, so the structured form
is how you attach detail.

An earlier version of this plugin offered C<< $c->otel_log >>, a second
logging call into a second logger. That is a design that goes wrong quietly:
the two diverge the first time somebody adds a line to one of them, and the
telemetry copy is always the one that gets forgotten. An application should
log the way it already logs.

=head2 A tap, not a sink

The line still goes wherever it was going - stderr, C<psgix.logger>, a C<to>
coderef - and the exporter receives a duplicate. Turning telemetry on never
takes an operator's logs away, and a collector outage never silences them.
Nobody should have to weigh having their logs against exporting them.

=head2 It needs Punk 0.34

Correlation needs the context, and C<pk_abi> only began passing it to log
observers at version 4. Against an older Punk the logs signal exports
B<nothing> rather than exporting records with no trace id - which would look
like working correlation that never joins up.

C<< Punk::OpenTelemetry::Instrument::install >> reports this: the C<logs> key
of its return is false when the ABI is too old.

=head2 The SDK's own diagnostics do not come back round

A record emitted while the exporter is working is dropped rather than queued.
Without that, one collector outage becomes an unbounded loop of telemetry
about failing to send telemetry.

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
