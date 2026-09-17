package Punk::Plugin::Observe;

use 5.010;
use strict;
use warnings;
use Carp ();

use Punk::Observe ();
use Punk::Observe::Ingest ();
use Punk::Observe::Store ();
use Punk::Observe::View ();
use Punk::Observe::Live ();
use Punk::Observe::Plot ();
use Punk::Observe::Segment ();
use Punk::Observe::Tenant ();
use Punk::Observe::Config ();
use Punk::Observe::Query ();
use File::Raw::JSON ();
use File::Basename ();
use File::Spec ();

our $VERSION = $Punk::Observe::VERSION;

our $INSECURE_ENV = 'PUNK_OBSERVE_INSECURE';

my %STATE;
sub state_for { return $STATE{ $_[1] } }

my %ASSET_TYPE = (
    'observe.css'   => 'text/css',
    'brush.js'      => 'application/javascript',
    'waterfall.js'  => 'application/javascript',
    'flamegraph.js' => 'application/javascript',
    'livetail.js'   => 'application/javascript',
    'discover.js'   => 'application/javascript',
    'defer.js'      => 'application/javascript',
    'nsmath.js'     => 'application/javascript',
    'plot.js'       => 'application/javascript',
    'plotly.min.js' => 'application/javascript',
    'moment.min.js'      => 'application/javascript',
    'daterangepicker.js' => 'application/javascript',
    'daterangepicker.css' => 'text/css',
    'daterange.js'       => 'application/javascript',
);

sub register {
    my ($class, $app, $opts) = @_;
    $opts = {} unless ref $opts eq 'HASH';

    Carp::croak(
        "Punk::Plugin::Observe: a guard is required - "
      . "plugin 'Observe' => { guard => 'Web::Auth#observe_admin' }. "
      . "An unguarded mount serves every log line this application has "
      . "written to anybody who finds the prefix. Set $INSECURE_ENV to mean "
      . "it.")
        unless $opts->{guard} or $ENV{$INSECURE_ENV};

    my $prefix = $opts->{prefix};
    $prefix = '/observe' unless defined $prefix && length $prefix;
    $prefix =~ s{/\z}{};

    my $st = {
        app     => $app,
        opts    => $opts,
        prefix  => $prefix,
        store   => $opts->{store},
        tenant  => _tenant($opts),
        ingest  => _ingest($opts),
        limits  => _limits($opts),
        stores  => {},
    };
    $st->{arena} = _arena($st);
    $st->{retain_opts} = _retain($opts);
    $st->{warm_opts}   = _warm($opts, $st->{retain_opts});
    $st->{db}    = _backend($st);
    # The alerts option carries two shapes: a seam (a coderef, or a hashref
    # with read/write/delete or the static rules) and the POLICY hash
    # (every, group_wait, repeat_interval). The policy is not a seam, and
    # taken as one it became a reader that read nothing, so the alerts page
    # said "No alert rules yet" over a store full of them.
    $st->{seam}  = { alerts     => _seam(_alerts_policy_only($opts->{alerts}) ? undef : $opts->{alerts}),
                     dashboards => _seam($opts->{dashboards}) };
    $st->{alerts_opts} = _alerts_opts($opts);

    $st->{writable} = _writable($st);

    _register_ui($st);
    _register_ingest($st);
    _register_jobs($st);

    my $key = ref($app) || $app;
    $STATE{$key} = $st if defined $key && length $key;
    return $st;
}

sub _alerts_opts {
    my ($opts) = @_;
    my $a = ref $opts->{alerts} eq 'HASH' && !exists $opts->{alerts}{read}
          ? $opts->{alerts} : {};
    my %out = ( group_wait_ns => 30_000_000_000, repeat_ns => 0,
                every => '@every 30s' );
    if (defined $a->{group_wait} && length $a->{group_wait}) {
        my ($ns) = Punk::Observe::View::min_duration($a->{group_wait});
        $out{group_wait_ns} = $ns if defined $ns;
    }
    if (defined $a->{repeat_interval} && length $a->{repeat_interval}) {
        my ($ns) = Punk::Observe::View::min_duration($a->{repeat_interval});
        $out{repeat_ns} = $ns if defined $ns;
    }
    $out{every} = $a->{every} if defined $a->{every} && length $a->{every};
    return \%out;
}

sub _register_jobs {
    my ($st) = @_;
    return unless $st->{db};
    my $own_alerts = $st->{seam}{alerts} && $st->{seam}{alerts}{read};

    my $app   = $st->{app};
    my $class = ref($app) || $app;
    my $kw    = ($app->can('caller_class') && $app->caller_class) || $class;
    my $task  = $kw->can('task');
    my $cron  = $kw->can('cron');
    Carp::croak(
        "plugin 'Observe': alerting needs plugin 'Queue' - "
      . "`use Punk::Plugin::Queue` and register plugin 'Queue' before "
      . "plugin 'Observe', or pass an `alerts` seam to keep your own "
      . "evaluator.") unless $task && $cron || $own_alerts;
    if ($own_alerts && !($task && $cron)) {
        Carp::croak("plugin 'Observe': retain is configured but there is no "
                  . "queue to schedule it on - register plugin 'Queue', or "
                  . "run retention yourself and drop the option")
            if $st->{retain_opts};
        return;
    }

    unless ($own_alerts) {
    $task->('observe.evaluate', '+Punk::Observe::Evaluate#evaluate_job');
    $task->('observe.notify',   '+Punk::Observe::Evaluate#notify_job',
            { attempts => 5 });

    $cron->($st->{alerts_opts}{every}, 'observe.evaluate',
            { name => 'observe-evaluate', args => [ $class ] });
    }

    $task->('observe.health', '+Punk::Observe::Health#health_job');
    $cron->('* * * * *', 'observe.health',
            { name => 'observe-health', args => [ $class ] });

    if ($st->{retain_opts}) {
        $task->('observe.retain', '+Punk::Observe::Retain#retain_job');
        $cron->($st->{retain_opts}{at}, 'observe.retain',
                { name => 'observe-retain', args => [ $class ] });
    }

    if ($st->{warm_opts}) {
        $task->('observe.warm', '+Punk::Observe::Warm#warm_job');
        $cron->($st->{warm_opts}{every}, 'observe.warm',
                { name => 'observe-warm', args => [ $class ] });
    }
    return 1;
}

sub _backend {
    my ($st) = @_;
    my $db = $st->{opts}{db};
    return undef if defined $db && !$db;

    my %arg;
    if (ref $db eq 'HASH')  { %arg = %$db }
    elsif (ref $db)         { return $db }
    elsif (defined $db && length $db) { $arg{dsn} = $db }
    else {
        return undef unless defined $st->{store} && length $st->{store};
        require File::Spec;
        $arg{dsn} = 'dbi:SQLite:dbname='
                  . File::Spec->catfile($st->{store}, 'config.db');
    }

    my $b = eval {
        require Punk::Observe::Backend;
        my $o = Punk::Observe::Backend->new(%arg);
        $o->migrate;
        $o->disconnect;
        $o;
    };
    if (!$b) {
        my $why = $@ || 'unknown error';
        $why =~ s/\s+\z//;
        Carp::carp("Punk::Plugin::Observe: the configuration store is "
                 . "unavailable, so editing is off - $why");
        return undef;
    }
    return $b;
}

sub _identity {
    my ($st, $c) = @_;
    my $cb = $st->{opts}{identity} or return undef;
    my $id = eval { $cb->($c) };
    if ($@) {
        my $why = $@; $why =~ s/\s+\z//;
        Carp::carp("Punk::Plugin::Observe: the identity seam died - $why");
        return undef;
    }
    return undef unless defined $id && length $id;
    return substr $id, 0, 200;
}

sub _seam {
    my ($v) = @_;
    return undef unless $v;
    return { read => $v } if ref $v eq 'CODE';
    return $v if ref $v eq 'HASH' && ($v->{read} || $v->{write} || $v->{delete});
    return { read => $v };
}

# The alerts POLICY hash, as opposed to a seam or static rules: only the
# three cadence keys, and none of read, write, delete or rules.
sub _alerts_policy_only {
    my ($v) = @_;
    return 0 unless ref $v eq 'HASH' && %$v;
    return 0 if grep { exists $v->{$_} } qw(read write delete rules silences events);
    my %policy = map { $_ => 1 } qw(every group_wait repeat_interval);
    return (grep { !$policy{$_} } keys %$v) ? 0 : 1;
}

sub _reader {
    my ($st, $kind) = @_;
    return sub {
        my @a = @_;
        my $req = ref $a[-1] eq 'HASH' ? $a[-1] : {};
        my $t = _request_tenant($st, $req->{c});
        return $kind eq 'dashboards'
             ? Punk::Observe::Config::dashboards($st->{db}, $t, $a[0])
             : Punk::Observe::Config::alerts($st->{db}, $t, $req);
    };
}

sub _writable {
    my ($st) = @_;
    my $want = $st->{opts}{writable};
    return 0 if defined $want && !$want;
    return 0 unless $st->{db} || ($st->{seam}{dashboards}
                                  && $st->{seam}{dashboards}{write});

    my $app = $st->{app};
    my $csrf = eval { ref $app eq 'HASH' ? $app->{csrf} : $app->{csrf} };
    return 1 if $csrf;
    return 1 if $ENV{$INSECURE_ENV};
    return 0;
}

sub _tenant {
    my ($opts) = @_;
    my $t = $opts->{tenant};

    return { fixed => 'default', resolver => undef }
        unless defined $t;
    return { fixed => 'default', resolver => $t } if ref $t eq 'CODE';

    my $chk = Punk::Observe::Tenant::check($t);
    Carp::croak("Punk::Plugin::Observe: tenant '$t' is not usable - "
              . $chk->{reason})
        unless $chk->{ok};
    return { fixed => $t, resolver => undef };
}

sub _ingest {
    my ($opts) = @_;
    my $i = $opts->{ingest};
    return undef unless $i;
    $i = {} unless ref $i eq 'HASH';

    my $prefix = $i->{prefix};
    $prefix = '/v1' unless defined $prefix && length $prefix;
    $prefix =~ s{/\z}{};

    my %out = (prefix => $prefix, keys => $i->{keys});
    $out{$_} = $i->{$_} for grep { defined $i->{$_} }
                            qw(max_body max_ratio max_records grpc);

    my %known = map { $_ => 1 }
                qw(prefix keys max_body max_ratio max_records grpc);
    my @bad = sort grep { !$known{$_} } keys %$i;
    Carp::croak("Punk::Plugin::Observe: unknown ingest option"
              . (@bad > 1 ? 's' : '') . ": " . join(', ', @bad)
              . ". Accepted: " . join(', ', sort keys %known))
        if @bad;

    return \%out;
}

sub _limits {
    my ($opts) = @_;
    my $l = $opts->{limits};
    $l = {} unless ref $l eq 'HASH';
    return {
        rate_records => $l->{rate_records} || 0,
        rate_bytes   => $l->{rate_bytes}   || 0,
        series       => defined $l->{series} ? $l->{series} : 1_000_000,
        series_window => $l->{series_window},
        storage      => $l->{storage} || 0,
        attributes   => $l->{attributes},
    };
}

sub _retain {
    my ($opts) = @_;
    my $r = $opts->{retain};
    return undef unless $r;
    $r = { keep => $r } unless ref $r;
    Carp::croak("Punk::Plugin::Observe: retain needs keep => '7d' (or 30d, "
              . "12h ...)") unless defined $r->{keep};
    require Punk::Observe::Retain;
    my $ns = Punk::Observe::Retain::parse_keep($r->{keep});
    Carp::croak("Punk::Plugin::Observe: retain keep '$r->{keep}' is not a "
              . "window - a number and a unit, as in 7d")
        unless defined $ns;
    my $at = defined $r->{at} ? $r->{at} : '17 * * * *';
    {
        local $@;
        eval { require Punk::Queue::Cron;
               Punk::Queue::Cron->check($at); 1 }
            or Carp::croak("Punk::Plugin::Observe: retain at '$at' is not "
                         . "a cron expression: $@");
    }
    my $bytes;
    if (defined $r->{bytes}) {
        my %mult = (k => 1024, m => 1024**2, g => 1024**3, t => 1024**4);
        if ($r->{bytes} =~ /\A\s*(\d+(?:\.\d+)?)\s*(?:([kmgt])i?b?|b)?\s*\z/i) {
            my ($n, $u) = ($1, $2);
            $bytes = sprintf '%.0f', $n * ($u ? $mult{lc $u} : 1);
        }
        Carp::croak("Punk::Plugin::Observe: retain bytes '$r->{bytes}' is "
                  . "not a size - a number and a unit, as in 500M or 2G")
            unless defined $bytes && $bytes > 0;
    }

    return { keep => $r->{keep}, keep_ns => $ns, at => $at,
             (defined $bytes ? (bytes => $bytes) : ()) };
}

# THE WARMER, ON UNLESS TURNED OFF, for the same reason the cache it fills is:
# a dashboard that is only fast for the people who read the documentation is a
# dashboard that is slow. It needs the cache, so `cache => 0` turns it off too
# rather than leaving a job that can only ever compute and discard.
sub _warm {
    my ($opts, $retain) = @_;
    my $w = exists $opts->{warm} ? $opts->{warm} : {};
    return undef unless $w;
    return undef if exists $opts->{cache} && !$opts->{cache};
    $w = {} unless ref $w eq 'HASH';

    require Punk::Observe::Retain;
    require Punk::Observe::Warm;
    my %out;
    my %window = (depth => 'depth_ns', refresh => 'refresh_ns');
    for my $k (sort keys %window) {
        next unless defined $w->{$k} && length $w->{$k};
        my $ns = Punk::Observe::Retain::parse_keep($w->{$k});
        Carp::croak("Punk::Plugin::Observe: warm $k '$w->{$k}' is not a "
                  . "window - a number and a unit, as in 7d")
            unless defined $ns;
        $out{ $window{$k} } = $ns;
    }
    if (defined $w->{ttl} && length $w->{ttl}) {
        my $ns = Punk::Observe::Retain::parse_keep($w->{ttl});
        Carp::croak("Punk::Plugin::Observe: warm ttl '$w->{ttl}' is not a "
                  . "window - a number and a unit, as in 8d")
            unless defined $ns;
        $out{ttl} = int($ns / 1_000_000_000);
    }
    for my $k (qw(budget timeout)) {
        next unless defined $w->{$k};
        Carp::croak("Punk::Plugin::Observe: warm $k must be a positive number")
            unless $w->{$k} =~ /\A\d+(?:\.\d+)?\z/ && $w->{$k} > 0;
        $out{$k} = $w->{$k};
    }

    # WARMING PAST THE HORIZON IS WORK OVER DATA THAT IS GONE. Retention
    # deletes segments; a chunk covering a window with nothing left in it is
    # computed, stored and never right again.
    if ($retain && $retain->{keep_ns}) {
        my $depth = $out{depth_ns} || Punk::Observe::Warm::DEPTH_NS();
        $out{depth_ns} = $retain->{keep_ns} if $retain->{keep_ns} < $depth;
    }

    my $every = defined $w->{every} ? $w->{every} : '@every 5m';
    {
        local $@;
        eval { require Punk::Queue::Cron;
               Punk::Queue::Cron->check($every); 1 }
            or Carp::croak("Punk::Plugin::Observe: warm every '$every' is "
                         . "not a cron expression: $@");
    }
    $out{every} = $every;
    return \%out;
}

sub _arena {
    my ($st) = @_;
    my $h = eval { Punk::Observe::Segment::shm_new($st->{limits}{series} || 0) };
    return undef unless defined $h;
    if (my $w = $st->{limits}{series_window}) {
        require Punk::Observe::Retain;
        my $ns = $w =~ /\A\d+\z/ ? $w : Punk::Observe::Retain::parse_keep($w);
        Carp::croak("Punk::Plugin::Observe: limits.series_window '$w' is not "
                  . "a window - a number and a unit, as in 24h") unless $ns;
        Punk::Observe::Segment::shm_window($h, $ns);
    }
    my $ok = eval { Punk::Observe::Segment::shm_stats($h) };
    return { handle => $h, shared => ($ok && $ok->{shared}) ? 1 : 0 };
}

sub _resolve_guard {
    my ($st) = @_;
    my $g = $st->{opts}{guard};
    return sub { return } unless $g;
    return $g if ref $g eq 'CODE';
    my ($ctrl, $action) = split /#/, $g, 2;
    Carp::croak("Punk::Plugin::Observe: guard '$g' is not Controller#action")
        unless defined $ctrl && defined $action && length $action;
    return $g;
}

sub _register_ui {
    my ($st) = @_;
    my $app = $st->{app};
    my $guard = _resolve_guard($st);
    return unless $app && $app->can('under');
    my $scope = $app->under($st->{prefix} => $guard);
    $st->{scope} = $scope;

    _build_views($st);
    $scope->get('/'        => sub { _page($st, 'status',    $_[0]) });
    $scope->get('/status'  => sub { _page($st, 'status',    $_[0]) });
    $scope->get('/logs'    => sub { _page($st, 'logs',      $_[0]) });
    $scope->get('/metrics' => sub { _page($st, 'metrics',   $_[0]) });
    $scope->get('/map'     => sub { _page($st, 'map',       $_[0]) });
    $scope->get('/traces'  => sub { _page($st, 'trace',     $_[0]) });
    $scope->get('/explore' => sub { _page($st, 'explore',   $_[0]) });
    $scope->get('/alerts'  => sub { _page($st, 'alerts',    $_[0]) });
    $scope->get('/help'    => sub { _page($st, 'help',      $_[0]) });
    $scope->get('/alerts/new' => sub {
        _page($st, 'alerts', $_[0], { template => 'alertedit', editing => 1,
                                      creating => 1,
                                      _alert_form_vars({}) });
    });
    $scope->get('/alerts/:id'     => sub { _page($st, 'alerts',    $_[0]) });
    $scope->get('/alerts/:id/edit' => sub {
        my ($c) = @_;
        my $rule = $st->{db}
            ? Punk::Observe::Config::alert($st->{db},
                  _request_tenant($st, $c), scalar eval { $c->param('id') })
            : undef;
        return $c->status(404)->text("no such rule\n") unless $rule;
        _page($st, 'alerts', $c, { template => 'alertedit', editing => 1,
                                   _alert_form_vars($rule) });
    });
    $scope->get('/dashboards'     => sub { _page($st, 'dashboard', $_[0]) });
    $scope->get('/dashboards/new' => sub {
        _page($st, 'dashboard', $_[0], { template => 'dashedit', editing => 1,
                                         creating => 1 });
    });
    $scope->get('/dashboards/:slug' => sub { _page($st, 'dashboard', $_[0]) });
    $scope->get('/health' => sub {
        _page($st, 'status', $_[0], { template => 'health',
                                      heading => 'Health',
                                      here_status => 0, here_home => 0,
                                      here_health => 1 });
    });
    $scope->get('/status.slow' => sub { _slow_panel($st, $_[0], 'status') });
    $scope->get('/health.slow' => sub { _slow_panel($st, $_[0], 'health') });
    $scope->get('/dashboards/:slug/panels/:key/slow' => sub {
        _dash_panel($st, $_[0]);
    });
    $scope->get('/health-targets/edit' => sub {
        _page($st, 'status', $_[0], { template => 'healthedit',
                                      heading  => 'Health targets',
                                      here_status => 0, here_home => 0,
                                      here_health => 1 });
    });
    $scope->get('/dashboards/:slug/edit' => sub {
        _page($st, 'dashboard', $_[0], { template => 'dashedit', editing => 1 });
    });
    if ($st->{writable}) {
        $scope->post('/dashboards' => sub { _write($st, 'dashboard', $_[0]) });
        $scope->post('/dashboards/:slug'
                     => sub { _write($st, 'dashboard', $_[0]) });
        $scope->post('/dashboards/:slug/delete'
                     => sub { _write($st, 'dashboard_delete', $_[0]) });
        $scope->post('/dashboards/:slug/panels'
                     => sub { _write($st, 'panel', $_[0]) });
        $scope->post('/dashboards/:slug/panels/save'
                     => sub { _write($st, 'panels_save', $_[0]) });
        $scope->post('/dashboards/:slug/panels/:id'
                     => sub { _write($st, 'panel', $_[0]) });
        $scope->post('/dashboards/:slug/panels/:id/delete'
                     => sub { _write($st, 'panel_delete', $_[0]) });

        $scope->post('/views'            => sub { _write($st, 'view', $_[0]) });
        $scope->post('/views/:id/delete' => sub { _write($st, 'view_delete', $_[0]) });

        $scope->post('/alerts'             => sub { _write($st, 'alert', $_[0]) });
        $scope->post('/alerts/:id'         => sub { _write($st, 'alert', $_[0]) });
        $scope->post('/alerts/:id/delete'  => sub { _write($st, 'alert_delete', $_[0]) });
        $scope->post('/alerts/:id/silence' => sub { _write($st, 'silence', $_[0]) });
        $scope->post('/alerts/silences/:id/delete'
                     => sub { _write($st, 'silence_delete', $_[0]) });

        $scope->post('/health-targets'
                     => sub { _write($st, 'health_target', $_[0]) });
        $scope->post('/health-targets/:name/delete'
                     => sub { _write($st, 'health_target_delete', $_[0]) });
    }

    $scope->get('/logs/stream' => sub { _stream($st, $_[0]) });
    $scope->get('/logs/:id'      => sub { _page($st, 'record', $_[0]) });
    $scope->get('/traces/:trace' => sub { _page($st, 'trace',  $_[0]) });
    for my $asset (sort keys %ASSET_TYPE) {
        $scope->get("/assets/$asset" => sub { _asset($st, $_[0], $asset) });
    }
    $scope->get('/assets/favicon.svg' => sub { _favicon($st, $_[0]) });
    return $scope;
}

sub _root_dir {
    my $pm = $INC{'Punk/Plugin/Observe.pm'} or return undef;
    my $dir = File::Basename::dirname($pm);
    my @candidates = (File::Spec->catdir($dir, File::Spec->updir,
                                         'Observe', 'root'));
    my $up = $dir;
    for (1 .. 5) {
        $up = File::Spec->catdir($up, File::Spec->updir);
        push @candidates, File::Spec->catdir($up, 'root');
    }
    for my $c (@candidates) {
        return $c if -d File::Spec->catdir($c, 'templates');
    }
    return undef;
}

sub _build_views {
    my ($st) = @_;
    my $root = $st->{opts}{root} || _root_dir();
    $st->{root} = $root;
    return unless $root && eval { require Template::Stencil; 1 };
    $st->{stencil} = Template::Stencil->new({
        template_dir => File::Spec->catdir($root, 'templates'),
        wrapper      => 'layout.tmpl',
    });
    $st->{fragment} = Template::Stencil->new({
        template_dir => File::Spec->catdir($root, 'templates'),
    });
    return $st->{stencil};
}

sub _fragment_html {
    my ($st, $tmpl, $vars) = @_;
    return undef unless $st->{fragment};
    my $html = eval { $st->{fragment}->render($tmpl, $vars) };
    return undef if $@;
    return undef if defined $html && $html =~ /\A\s*\Q$tmpl\E\s*\z/;
    utf8::decode($html) if defined $html;
    return $html;
}

sub _ingest_vars {
    my ($store, $from, $to) = @_;
    my $fig = eval { Punk::Observe::Plot::ingest_figure($store, $from, $to) };
    return $fig ? (ingest_plot => $fig) : ();
}

sub _health_vars {
    my ($st, $store, $from, $to) = @_;
    return () unless $st->{db};
    my $h = eval {
        require Punk::Observe::Health;
        Punk::Observe::Health::page_vars(
            db => $st->{db}, store => $store,
            tenant => $st->{tenant}{fixed});
    };
    return () unless ref $h eq 'ARRAY' && @$h;

    my $dur = sub {
        my ($ns, $capped) = @_;
        my $s = Punk::Observe::View::fmt_dur($ns || 0);
        return $capped ? "over $s" : $s;
    };
    for my $t (@$h) {
        $t->{held_s} = $dur->($t->{held}, $t->{held_min});
        $t->{row_class} = $t->{ok} ? '' : 'row-error';
        for my $c (@{ $t->{checks} }) {
            $c->{held_s} = $dur->($c->{held}, $c->{held_min});
            $c->{row_class} = $c->{ok} ? '' : 'row-error';
        }
    }
    my %out = (health => $h);

    if (defined $from && defined $to && $store) {
        my $ev = eval { Punk::Observe::Health::uptime_events(
                            store => $store, from => $from, to => $to) };
        if (ref $ev eq 'ARRAY' && @$ev) {
            my $j = eval { Punk::Observe::Plot::timeline_figure(
                               { events => $ev, to => $to }) };
            if (defined $j && length $j) {
                utf8::decode($j);
                $out{health_up_plot} = $j;
            }
        }
    }
    return %out;
}

sub _status_window {
    my ($req) = @_;
    my ($from, $to) = Punk::Observe::View::window($req);
    if (!defined $from || !defined $to) {
        my $now = Punk::Observe::now_ns();
        $from = Punk::Observe::Store::nsub($now, 3_600 * 1_000_000_000);
        $to   = $now;
    }
    return ($from, $to);
}

sub _dash_panel {
    my ($st, $c) = @_;
    my $store = store_for($st, _request_tenant($st, $c));
    my $req   = _params($st, $c);
    $req->{panel} = eval { $c->param('key') };

    my $panel = eval { Punk::Observe::View->_panel($store, $req) };
    return $c->status(500)->text("panel build failed: $@") if $@;
    return $c->status(404)->text("that panel is not on this dashboard\n")
        unless ref $panel eq 'HASH';

    my ($w_from, $w_to) = _status_window($req);
    my $html = _fragment_html($st, q{panelslow.tmpl},
        { p => $panel, prefix => $st->{prefix},
          from => $w_from, to => $w_to,
          range_amp => _range_qs($req, q{&}) });
    return $c->status(500)->text('fragment render failed')
        unless defined $html;
    $c->header('Cache-Control' => 'no-cache');
    return $c->html($html);
}

sub _slow_panel {
    my ($st, $c, $which) = @_;
    my $store = store_for($st, _request_tenant($st, $c));
    my $req   = _params($st, $c);
    my %vars  = (prefix    => $st->{prefix},
                 writable  => $st->{writable},
                 range_qs  => _range_qs($req, '?'),
                 range_amp => _range_qs($req, '&'));
    if ($which eq 'status') {
        my ($from, $to) = _status_window($req);
        %vars = (%vars, _ingest_vars($store, $from, $to));
    }
    else {
        my ($from, $to) = _status_window($req);
        %vars = (%vars, _health_vars($st, $store, $from, $to));
    }
    my $html = _fragment_html($st, "${which}slow.tmpl", \%vars);
    return $c->status(500)->text('fragment render failed')
        unless defined $html;
    $c->header('Cache-Control' => 'no-cache');
    utf8::encode($html) if utf8::is_utf8($html);
    return $c->html($html);
}

sub _empty {
    my ($st, $c) = @_;
    return (
        prefix => $st->{prefix}, query => '', title => '', heading => '',
        theme => '', toolbar => '', width => 720, height => 220,
        root_name => '', span_count => 0, duration_ms => 0, orphans => 0,
        cycles => 0, spans => [], rows => [], series => [], nodes => [],
        edges => [], yticks => [], back_edges => 0, error => '', hint => '',
        refusal => '', truncated => 0, scanned => 0, tail => 0,
        query_esc => '', from => '0', to => '0',
        rules => [], silences => [], broken => 0, panels => [], cols => 2,
        slug => '',
        ingest_rate => 0, wal_depth => 0, segments => 0, compaction_lag => 0,
        series_used => 0, series_dropping => 0, overflow_records => 0,
        live_gaps => 0, older_cursor => '', paged => 0, next_cursor => '',
        series_cap => $st->{limits}{series} || 0,
        health => [],
        accepted => '0', accepted_bytes => '0 B',
        rate_rejected => '0', counters_shared => 1,

        groups => [], names => [], examples => [], traces => [], flame => [],
        attrs => [], context => [], services => [], columns => [],
        record => {}, found => 0, empty => 0, degraded => 0, exact => 1,
        offset => 0, shape => 'rows', total => 0, errors => 0,
        has_severity => 0, has_duration => 0, has_value => 0, has_trace => 0,
        errors_only => 0, min_ms => '', trace => '', flame_height => 0,
        logs => 0, metrics => 0, traces_seen => 0, store_bytes => '0 B',
        here_home => 0, here_map => 0, here_traces => 0, here_logs => 0,
        here_dashboard => 0,
        here_metrics => 0, here_explore => 0, here_alerts => 0,
        here_status => 0,
        range => '1h', range_all => 0, range_custom => 0, ranges => [],
        wants_range => 0, range_qs => '', range_amp => '',
        writable => 0, csrf_field => '', editing => 0, creating => 0,
        saved_views => [], save_page => '', save_path => '',
        sources => [], aggregates => [], severities => [], units => [],
        attr_keys => [], attrs_truncated => 0, attrs_sampled => 0,
        columns_source => '',
        operators => [],
        field => '', configured => 0, can_edit => 0, list => [],
    );
}

sub store_for {
    my ($st, $tenant) = @_;
    return undef unless defined $st->{store} && length $st->{store};
    $tenant = 'default' unless defined $tenant && length $tenant;
    return $st->{stores}{$tenant} ||= Punk::Observe::Store->new(
        dir        => $st->{store},
        tenant     => $tenant,
        seal_bytes => $st->{opts}{seal_bytes},
        max_rows   => $st->{opts}{max_rows},
        cache      => _query_cache($st),
    );
}

# THE CHUNK CACHE, BUILT ONCE PER WORKER AND SHARED BY EVERY TENANT'S STORE.
#
# A file store, because the point is that five workers rendering the same
# dashboard compute a chunk once between them - a per-worker memory cache
# would compute it five times and hold five copies. `compute` gives the
# single-flight on top of that.
#
# It lives beside the data it summarises rather than in a system temp
# directory: a cache of one store's history has no meaning next to another's,
# and an operator moving the store expects its derived files to go too.
#
# ON UNLESS TURNED OFF. A cache that has to be discovered is a cache nobody
# has, and every path through it falls back to the plain query - a store
# without Punk::Cache installed, an unwritable directory or a full disk all
# come out as a slower answer rather than a broken page.
sub _query_cache {
    my ($st) = @_;
    return $st->{query_cache} if exists $st->{query_cache};

    my $opt = $st->{opts}{cache};
    $opt = {} unless defined $opt;
    return $st->{query_cache} = undef unless $opt;      # cache => 0
    $opt = {} unless ref $opt eq 'HASH';

    $st->{query_cache} = eval {
        require Punk::Cache;
        require File::Spec;
        my $dir = $opt->{dir}
               || File::Spec->catdir($st->{store}, 'cache');
        Punk::Cache->new('file', dir => $dir,
                         max_bytes => $opt->{max_bytes} || '256M');
    };
    return $st->{query_cache};
}

sub _request_tenant {
    my ($st, $c) = @_;
    my $t = eval {
        Punk::Observe::Tenant::resolve($st->{tenant}{fixed},
                                       $st->{tenant}{resolver});
    };
    return ($t && $t->{ok}) ? $t->{tenant} : 'default';
}

sub _params {
    my ($st, $c) = @_;
    my %p;
    for my $k (qw(q from to range errors min_ms service id trace slug
                  before after)) {
        my $v = eval { $c->param($k) };
        $p{$k} = $v if defined $v && length $v;
    }
    for my $k (qw(alerts dashboards)) {
        my $seam = $st->{seam}{$k};
        $p{$k} = $seam->{read} if $seam && $seam->{read};
        $p{$k} = _reader($st, $k) if !$p{$k} && $st->{db};
    }
    $p{writable} = $st->{writable};
    return \%p;
}

sub _range_qs {
    my ($req, $lead) = @_;
    $lead = '?' unless defined $lead;
    if (defined $req->{from} && length $req->{from}
        && defined $req->{to} && length $req->{to}) {
        return $lead . 'from=' . _uri_esc($req->{from})
             . '&to=' . _uri_esc($req->{to});
    }
    return $lead . 'range=' . _uri_esc($req->{range})
        if defined $req->{range} && length $req->{range};
    return '';
}

sub _uri_esc {
    my ($v) = @_;
    $v = '' unless defined $v;
    $v =~ s/([^A-Za-z0-9_.~-])/sprintf('%%%02X', ord $1)/ge;
    return $v;
}

sub _discover {
    my ($st, $c, $name, $vars, $store, $req) = @_;

    my %src = (logs => 'log', metrics => 'metric', trace => 'trace',
               explore => '');
    my $source = $src{$name};

    if (!length $source && defined $req->{q} && $req->{q} =~ /\A\s*(\w+)/) {
        my %alias = (logs => 'log', traces => 'trace', span => 'spans');
        my $w = lc $1;
        $source = $alias{$w} || $w;
    }
    $source = 'log' unless length $source;

    my $g = Punk::Observe::Query::grammar();
    my $cols = $g->{columns}{$source} or return;

    $vars->{columns} = [ map { { name => $_, kind => 'column' } } @$cols ];
    $vars->{columns_source} = $source;

    my $q = defined $req->{q} && $req->{q} =~ /\S/ ? $req->{q} : '';
    $q =~ s/\A\s+|[\s|]+\z//g;
    my $base = $q;
    if (!length $base) {
        if ($source eq 'metric') {
            my $first = eval { $vars->{names}[0]{name} };
            $base = defined $first && length $first ? "metric $first" : '';
        }
        else { $base = $source }
    }
    return unless length $base;

    (my $stem = $base) =~ s/\s*\|.*\z//s;
    my %page = (logs => 'logs', metrics => 'metrics', trace => 'traces',
                explore => 'explore');
    $vars->{discover_page} = $page{$name} || 'explore';

    my $where_base = $base;

    return unless $store;
    return if $vars->{error};

    my %kind = (metric => 1, log => 2, trace => 3, spans => 3);

    my $LOOK = 2000;
    my %seen;
    my $sampled;
    my $gen  = eval { $store->can('generation') ? $store->generation : '' };
    $gen = '' unless defined $gen;
    my $ckey = join "\0", ($store->{tenant} // 'default'), $source,
                          map { $_ // '' } @{$req}{qw(range from to)};
    my $hit = $st->{discover}{$ckey};
    if ($hit && $hit->{gen} eq $gen && time - $hit->{at} < 60) {
        %seen    = %{ $hit->{seen} };
        $sampled = $hit->{sampled};
    }
    else {
        my $recs = eval {
            my ($r) = $store->records(from => $vars->{from},
                                      to => $vars->{to},
                                      limit => $LOOK,
                                      ($kind{$source}
                                         ? (kind => $kind{$source}) : ()));
            $r;
        };
        return unless ref $recs eq 'ARRAY';

        for my $rec (@$recs) {
            my $a = $rec->{attrs} or next;
            $seen{$_}++ for keys %$a;
        }
        $sampled = scalar @$recs;

        my $d = $st->{discover} ||= {};
        delete @$d{ grep { time - $d->{$_}{at} >= 60 } keys %$d };
        $d->{$ckey} = { gen => $gen, at => time,
                        seen => {%seen}, sampled => $sampled };
    }
    return unless %seen;

    my $allow = $st->{limits}{attributes};
    my %indexed = map { $_ => 1 }
                  ref $allow eq 'ARRAY' ? @$allow
                  : qw(service.name severity host.name deployment.environment);

    my @keys = sort { $seen{$b} <=> $seen{$a} || $a cmp $b } keys %seen;
    my $cap = 40;
    $vars->{attrs_truncated} = @keys > $cap ? 1 : 0;
    @keys = @keys[0 .. $cap - 1] if @keys > $cap;

    $vars->{attr_keys} = [ map {
        { name => $_, count => $seen{$_}, indexed => ($indexed{$_} ? 1 : 0),
          query => _uri_esc("$stem | by $_ | count"),
          where => "$where_base | where $_ = " }
    } @keys ];
    $vars->{attrs_sampled} = $sampled;
}

sub _dur_text {
    my ($ns) = @_;
    return '' unless defined $ns && $ns > 0;
    return Punk::Observe::View::fmt_dur($ns) if $ns % 1_000_000_000;
    my $s = $ns / 1_000_000_000;
    for my $u ([ 604_800 => 'w' ], [ 86_400 => 'd' ], [ 3_600 => 'h' ],
               [ 60 => 'm' ]) {
        return ($s / $u->[0]) . $u->[1] unless $s % $u->[0];
    }
    return "${s}s";
}

sub _alert_form_vars {
    my ($rule) = @_;
    my %r = %{ $rule || {} };
    for my $f (qw(for every)) {
        next if defined $r{$f};
        $r{$f} = _dur_text($r{"${f}_ns"});
    }
    my $cur = defined $r{op} ? $r{op} : '>';
    return (rule => \%r,
            op_options => [ map { { name => $_,
                                    current => ($_ eq $cur ? 1 : 0) } }
                            qw(> >= < <= == !=) ]);
}

sub _write {
    my ($st, $what, $c) = @_;

    return $c->status(503)->text("no configuration store\n") unless $st->{db};

    my $tenant = _request_tenant($st, $c);
    my $slug   = eval { $c->param('slug') };
    my $id     = eval { $c->param('id') };
    my %in     = map { $_ => scalar eval { $c->param($_) } }
                 qw(slug title cols query viz span position);

    my $r;
    if    ($what eq 'dashboard') {
        $in{slug} = $slug if defined $slug && length $slug;
        $r = Punk::Observe::Config::save_dashboard($st->{db}, $tenant, \%in);
    }
    elsif ($what eq 'dashboard_delete') {
        $r = Punk::Observe::Config::delete_dashboard($st->{db}, $tenant, $slug);
    }
    elsif ($what eq 'panel') {
        $in{id} = $id;
        $r = Punk::Observe::Config::save_panel($st->{db}, $tenant, $slug, \%in);
    }
    elsif ($what eq 'panel_delete') {
        $r = Punk::Observe::Config::delete_panel($st->{db}, $tenant, $slug, $id);
    }
    elsif ($what eq 'panels_save') {
        my $d = Punk::Observe::Config::dashboards($st->{db}, $tenant, $slug);
        my @rows;
        for my $p (@{ $d->{panels} || [] }) {
            my %row = map { $_ => scalar eval { $c->param("p$p->{id}_$_") } }
                      qw(title query viz span position);
            next unless grep { defined } values %row;
            $row{id} = $p->{id};
            push @rows, \%row;
        }
        $r = Punk::Observe::Config::save_panels($st->{db}, $tenant, $slug,
                                                \@rows);
    }
    elsif ($what eq 'view') {
        my %v = map { $_ => scalar eval { $c->param($_) } }
                qw(name page q from to range errors min_ms service);
        $r = Punk::Observe::Config::save_view($st->{db}, $tenant, \%v);
        if ($r->{ok}) {
            my $page = $v{page} || 'logs';
            $page = 'traces' if $page eq 'trace';
            my $qs = join '&', map { "$_=" . _uri_esc($v{$_}) }
                     grep { defined $v{$_} && length $v{$_} }
                     qw(q from to range errors min_ms service);
            return $c->redirect($st->{prefix} . "/$page"
                                . (length $qs ? "?$qs" : ''), 303);
        }
    }
    elsif ($what eq 'view_delete') {
        $r = Punk::Observe::Config::delete_view($st->{db}, $tenant, $id);
        if ($r->{ok}) {
            my $page = eval { $c->param('page') } || 'logs';
            $page = 'traces' if $page eq 'trace';
            return $c->redirect($st->{prefix} . "/$page", 303);
        }
    }
    elsif ($what eq 'alert') {
        my %a = map { $_ => scalar eval { $c->param($_) } }
                qw(name query op threshold for every enabled);
        $a{id} = $id if defined $id && length $id;
        $a{enabled} = 0 unless defined $a{enabled} && $a{enabled};
        $r = Punk::Observe::Config::save_alert($st->{db}, $tenant, \%a);
        return $c->redirect($st->{prefix} . '/alerts', 303) if $r->{ok};
        return _page($st, 'alerts', $c, {
            template => 'alertedit', editing => 1,
            creating => (defined $id && length $id) ? 0 : 1,
            _alert_form_vars({ %a, id => $id }),
            error    => $r->{error}, field => $r->{field} || '',
            hint     => $r->{refused}
                      ? 'Correct it and submit again.'
                      : 'The configuration store could not be written to.',
            status   => $r->{refused} ? 400 : 500,
        });
    }
    elsif ($what eq 'alert_delete') {
        $r = Punk::Observe::Config::delete_alert($st->{db}, $tenant, $id);
        return $c->redirect($st->{prefix} . '/alerts', 303) if $r->{ok};
    }
    elsif ($what eq 'silence') {
        my %s = map { $_ => scalar eval { $c->param($_) } }
                qw(pattern until reason);
        unless (defined $s{pattern} && length $s{pattern}) {
            my $rule = Punk::Observe::Config::alert($st->{db}, $tenant, $id);
            $s{pattern} = $rule ? "$rule->{name}/" : '';
        }
        $s{by} = eval { $c->current_user } || eval { $c->auth_id } || undef;
        $r = Punk::Observe::Config::save_silence($st->{db}, $tenant, \%s);
        return $c->redirect($st->{prefix} . '/alerts', 303) if $r->{ok};
    }
    elsif ($what eq 'silence_delete') {
        $r = Punk::Observe::Config::delete_silence($st->{db}, $tenant, $id);
        return $c->redirect($st->{prefix} . '/alerts', 303) if $r->{ok};
    }
    elsif ($what eq 'health_target') {
        my %t = map { $_ => scalar eval { $c->param($_) } }
                qw(name url every_s timeout_ms);
        $t{every_ns} = int($t{every_s} * 1_000_000_000)
            if defined $t{every_s} && length $t{every_s};
        delete $t{every_s};
        delete $t{$_} for grep { !defined $t{$_} } keys %t;
        $r = Punk::Observe::Config::save_health_target(
                 $st->{db}, $tenant, \%t, $st->{opts}{health_allow});
        return $c->redirect($st->{prefix} . '/health-targets/edit', 303)
            if $r->{ok};
    }
    elsif ($what eq 'health_target_delete') {
        my $name = eval { $c->param('name') };
        $r = Punk::Observe::Config::delete_health_target(
                 $st->{db}, $tenant, $name);
        return $c->redirect($st->{prefix} . '/health-targets/edit', 303)
            if $r->{ok};
    }
    else { $r = { ok => 0, error => "unknown write '$what'" } }

    if ($what =~ /\A(?:alert_delete|silence)/ && !$r->{ok}) {
        return _page($st, 'alerts', $c, {
            error  => $r->{error},
            hint   => $r->{refused}
                    ? 'Correct it and submit again.'
                    : 'The configuration store could not be written to.',
            status => $r->{refused} ? 400 : 500,
        });
    }

    if ($what =~ /\Ahealth_target/ && !$r->{ok}) {
        return _page($st, 'status', $c, {
            template => 'healthedit',
            heading  => 'Health targets',
            here_status => 0, here_home => 0, here_health => 1,
            error    => $r->{error},
            hint     => $r->{refused}
                      ? 'Correct it and submit again.'
                      : 'The configuration store could not be written to.',
            status   => $r->{refused} ? 400 : 500,
        });
    }

    my $back = $st->{prefix} . '/dashboards';
    if ($r->{ok}) {
        $back .= '/' . _uri_esc($slug)
            if defined $slug && length $slug && $what ne 'dashboard_delete';
        return $c->redirect($back, 303);
    }

    my $status = $r->{refused} ? 400 : 500;
    return _page($st, 'dashboard', $c, {
        template => 'dashedit',
        editing  => 1,
        creating => ($what eq 'dashboard' && !(defined $slug && length $slug)) ? 1 : 0,
        error    => $r->{error},
        field    => $r->{field} || '',
        hint     => $r->{refused}
                  ? 'Correct it and submit again.'
                  : 'The configuration store could not be written to.',
        status   => $status,
    });
}

sub _page {
    my ($st, $name, $c, $over) = @_;
    return $c->status(501)->text("Template::Stencil is not installed\n")
        unless $st->{stencil};

    my %vars = _empty($st, $c);
    my $req  = _params($st, $c);
    my $store = store_for($st, _request_tenant($st, $c));

    my $dash_full = 0;
    if ($name eq 'dashboard'
        && (ref $over ne 'HASH' || ($over->{template} || '') ne 'dashedit')) {
        $dash_full = ($c && eval { $c->param('full') }) || !$st->{fragment}
                   ? 1 : 0;
        $req->{panels_inline} = 1 if $dash_full;
    }

    my $built = eval { Punk::Observe::View->page($store, $name, $req) };
    if ($@) {
        $vars{error} = 'That screen could not be built from the store.';
        $vars{hint}  = "$@";
    }
    elsif (ref $built eq 'HASH') {
        %vars = (%vars, %$built);
    }

    if ($dash_full) {
        for my $p (@{ $vars{panels} || [] }) {
            my $html = _fragment_html($st, q{panelslow.tmpl},
                { p => $p, prefix => $st->{prefix},
                  from => $vars{from}, to => $vars{to},
                  range_amp => _range_qs($req, q{&}) });
            $p->{body_html} = $html if defined $html;
        }
    }

    $vars{heading} = ucfirst $name unless length($vars{heading} || '');
    $vars{writable}   = $st->{writable} ? 1 : 0;
    $vars{csrf_field} = ($st->{writable} && $c && $c->can('csrf_field'))
                      ? (eval { $c->csrf_field } || '') : '';

    if ($name eq 'help') {
        my $g = Punk::Observe::Query::grammar();
        $vars{$_} = $g->{$_} for qw(aggregates severities units operators);
        $vars{sources} = [ map {
            { %$_, alias => ($_->{alias} // ''),
              cols => join ', ', @{ $g->{columns}{ $_->{name} } || [] } }
        } @{ $g->{sources} } ];
        $vars{heading} = 'The query language';
        $vars{title}   = 'The query language';
    }

    if ($st->{db} || $store) {
        if ($name =~ /\A(?:explore|logs|metrics|trace)\z/) {
            _discover($st, $c, $name, \%vars, $store, $req);
        }
    }

    if ($st->{db} && $name =~ /\A(?:logs|metrics|trace|explore)\z/) {
        my $vs = eval { Punk::Observe::Config::saved_views($st->{db},
                                                           _request_tenant($st, $c),
                                                           $name) };
        $vars{saved_views} = (ref $vs eq 'ARRAY') ? $vs : [];
        $vars{save_page}   = $name;
        $vars{save_path}   = $name eq 'trace' ? 'traces' : $name;
    }

    $vars{range_qs}  = _range_qs($req, '?');
    $vars{range_amp} = _range_qs($req, '&');

    if ($name eq 'status' && $store) {
        my $s = delete $vars{_stats};
        $s = eval { $store->stats } || {} unless ref $s eq 'HASH';

        my $fig = Punk::Observe::Plot::gauge(
            value => $s->{bytes} || 0,
            max   => $st->{limits}{storage} || 0,
            title => 'bytes on disk');
        $vars{storage_gauge_plot} = Punk::Observe::Plot::encode($fig) if $fig;

        my $tname = (ref $over eq 'HASH' && $over->{template})
                  || $vars{template} || 'status';
        my $full  = $c ? (eval { $c->param('full') } ? 1 : 0) : 0;
        my %fvars = (prefix    => $st->{prefix},
                     writable  => $st->{writable},
                     range_qs  => _range_qs($req, '?'),
                     range_amp => _range_qs($req, '&'));

        if ($tname eq 'status') {
            if ($full || !$st->{fragment}) {
                my ($from, $to) = _status_window($req);
                $vars{ingest_html} = _fragment_html($st, 'statusslow.tmpl',
                    { %fvars, _ingest_vars($store, $from, $to) });
            }
        }
        elsif ($tname eq 'health') {
            if ($full || !$st->{fragment}) {
                my ($hf, $ht) = _status_window($req);
                $vars{health_html} = _fragment_html($st, "healthslow.tmpl",
                    { %fvars, _health_vars($st, $store, $hf, $ht) });
            }
        }
        elsif ($tname eq 'healthedit') {
            my %h = _health_vars($st, $store);
            @vars{keys %h} = values %h;
        }

        my $c = $st->{arena}
              ? eval { Punk::Observe::Segment::shm_stats($st->{arena}{handle}) }
              : undef;
        if ($c) {
            $vars{accepted}       = Punk::Observe::View::fmt_count($c->{records});
            $vars{accepted_bytes} = Punk::Observe::View::fmt_bytes($c->{bytes});
            $vars{rate_rejected}  = Punk::Observe::View::fmt_count($c->{rate_rejected});
            $vars{counters_shared} = $c->{shared} ? 1 : 0;

            $vars{series_used}     = Punk::Observe::View::fmt_count($c->{series});
            $vars{series_cap}      = $c->{series_cap}
                                   ? Punk::Observe::View::fmt_count($c->{series_cap}) : '';
            $vars{series_rejected} = Punk::Observe::View::fmt_count($c->{rejected});
            $vars{series_dropping} = ($c->{rejected} || 0) > 0 ? 1 : 0;
            $vars{overflow_records} = Punk::Observe::View::fmt_count($c->{overflow});

            $vars{live_gaps} = Punk::Observe::View::fmt_count($c->{live_gaps});

            if ($c->{series_cap}) {
                my $g = Punk::Observe::Plot::gauge(
                    value => $c->{series} || 0,
                    max   => $c->{series_cap},
                    title => 'active series');
                $vars{series_gauge_plot} = Punk::Observe::Plot::encode($g) if $g;
            }
        }
    }

    $vars{wants_plot} = (grep { /_plot\z/ && defined $vars{$_} && length $vars{$_} }
                         keys %vars) ? 1 : 0;
    $vars{wants_plot} ||= (grep {
        my $p = $_;
        ref $p eq 'HASH'
            && grep { /_plot\z/ && defined $p->{$_} && length $p->{$_} } keys %$p;
    } @{ $vars{panels} || [] }) ? 1 : 0;
    $vars{wants_plot} ||= ($name eq 'dashboard' && !$dash_full
                           && (ref $over ne 'HASH'
                               || ($over->{template} || '') ne 'dashedit')
                           && @{ $vars{panels} || [] }) ? 1 : 0;

    if (my $cb = $st->{opts}{stats}) {
        my $extra = eval { $cb->($c, $name, $store) };
        if ($@) {
            my $why = $@; $why =~ s/\s+\z//;
            Carp::carp("Punk::Plugin::Observe: the stats callback died on "
                     . "the $name screen - $why");
        }
        %vars = (%vars, %$extra) if ref $extra eq 'HASH';
    }

    my ($status, $use);
    if (ref $over eq 'HASH') {
        $status = delete $over->{status};
        $use    = delete $over->{template};
        %vars = (%vars, %$over);
    }

    if ($vars{editing}) {
        my @viz = Punk::Observe::Dashboard::viz_names();
        $vars{viz_options} = [ map { { name => $_ } } @viz ];
        for my $p (@{ $vars{panels} || [] }) {
            my $cur = $p->{viz} || 'line';
            $p->{viz_options} = [ map { { name => $_,
                                          current => ($_ eq $cur ? 1 : 0) } } @viz ];
        }
    }

    if (my $f = $vars{field}) { $vars{"field_$f"} = 1 }

    my $tmpl = ($use || $name) . '.tmpl';
    my $html = eval { $st->{stencil}->render($tmpl, \%vars) };
    return $c->status(500)->text("render failed: $@") if $@;
    # The name-or-source guess: a template name that transiently fails to
    # resolve renders AS SOURCE - a 200 whose whole body is the file name.
    # See _fragment_html; a page five words long is a 500, not an answer.
    return $c->status(500)->text("template '$tmpl' did not resolve\n")
        if defined $html && $html =~ /\A\s*\Q$tmpl\E\s*\z/;
    $c->status($status) if $status;
    return $c->html($html);
}

sub _stream {
    my ($st, $c) = @_;
    my $store = store_for($st, _request_tenant($st, $c));

    $c->header('Content-Type'      => 'text/event-stream');
    $c->header('Cache-Control'     => 'no-cache');
    $c->header('X-Accel-Buffering' => 'no');

    my $req = _params($st, $c);
    my $q = $req->{q};
    $q = 'log' unless defined $q && $q =~ /\S/;

    my $since = eval { $c->param('since') };
    $since = eval { $c->req->header('Last-Event-ID') } unless defined $since;
    $since = undef unless defined $since && $since =~ /\A\d+\z/ && $since > 0;

    my $body = sprintf("retry: %d\n\n", 2000);
    if ($store) {
        my $r = eval { $store->query($q, limit => 200) } || {};
        my @rows = reverse @{ $r->{rows} || [] };
        if (defined $since) {
            @rows = grep { Punk::Observe::Store::ncmp($_->{t}, $since) > 0 } @rows;
        }
        elsif (@rows > 50) {
            splice @rows, 0, @rows - 50;
        }
        for my $row (@rows) {
            $body .= Punk::Observe::Live::sse($row->{t}, 'log',
                                              _tail_json($row));
        }
    }
    $body .= Punk::Observe::Live::heartbeat();
    return $c->text($body);
}

sub _tail_json {
    my ($row) = @_;
    return '{' . join(',', map { _json_pair(@$_) }
        [ 'id',       Punk::Observe::View::record_id($row) ],
        [ 'time',     Punk::Observe::View::fmt_time($row->{t}) ],
        [ 'sev_name', Punk::Observe::View::severity_name($row->{severity}) ],
        [ 'service',  (defined $row->{service} ? $row->{service} : '') ],
        [ 'body',     (defined $row->{body}    ? $row->{body}    : '') ],
    ) . '}';
}

sub _json_pair {
    my ($k, $v) = @_;
    $v = '' unless defined $v;
    $v =~ s/([\\"])/\\$1/g;
    $v =~ s/([\x00-\x1f])/sprintf('\\u%04x', ord $1)/ge;
    return "\"$k\":\"$v\"";
}

sub _asset {
    my ($st, $c, $name) = @_;
    $name = 'observe.css' unless defined $name && $ASSET_TYPE{$name};
    my $path = File::Spec->catfile($st->{root} || '', 'static', $name);
    return $c->status(404)->text("no such asset\n") unless -f $path;

    my $enc;
    my $ae = eval { $c->req->header('Accept-Encoding') };
    if (defined $ae && $ae =~ /\bgzip\b/ && -f "$path.gz") {
        $path .= '.gz';
        $enc = 'gzip';
    }

    $c->header('Vary' => 'Accept-Encoding');
    $c->header('Content-Encoding' => $enc) if $enc;

    return $c->send_file($path,
        type          => $ASSET_TYPE{$name},
        cache_control => 'no-cache',
        missing       => 'not_found');
}

my $FAVICON = <<'SVG';
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
<rect width="32" height="32" rx="7" fill="#151821"/>
<path d="M4 21 L10 21 L13 11 L17 25 L20 17 L23 17"
      fill="none" stroke="#6ee7b7" stroke-width="2.5"
      stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="26" cy="9" r="3.5" fill="#f87171"/>
</svg>
SVG

sub _favicon {
    my ($st, $c) = @_;
    $st->{favicon_etag} //= sprintf('"%08x"', length($FAVICON) ^ 0x5f5f5f5f);
    my $inm = eval { $c->req->header('If-None-Match') } || '';
    return $c->status(304)->text('') if $inm eq $st->{favicon_etag};
    $c->header('Content-Type'  => 'image/svg+xml');
    $c->header('ETag'          => $st->{favicon_etag});
    $c->header('Cache-Control' => 'public, max-age=86400');
    return $c->text($FAVICON);
}

sub _register_ingest {
    my ($st) = @_;
    my $i = $st->{ingest} or return;
    my $app = $st->{app};

    my $keys = _keyring($st);
    my $store = $st->{store};

    my $recv = Punk::Observe::Ingest->new(
        max_body => $i->{max_body},
        auth     => sub {
            my ($env) = @_;
            return undef unless _key_ok($keys, $env);
            my $t = Punk::Observe::Tenant::resolve(
                        $st->{tenant}{fixed}, $st->{tenant}{resolver});
            return $t->{ok} ? $t->{tenant} : undef;
        },
        on_batch => sub {
            my ($tenant, $signal, $body, $encoding, $out) = @_;
            return _persist($st, $tenant, $signal, $body, $encoding, $out);
        },
    );

    $st->{receiver} = $recv;
    my $inner = $recv->to_app;
    $st->{ingest_app} = sub {
        my ($env) = @_;
        local $env->{PATH_INFO} = '/v1' . ($env->{PATH_INFO} // '');
        return $inner->($env);
    };

    return unless $app && $app->can('mount');
    $app->mount($i->{prefix} => $st->{ingest_app});
    return $st->{ingest_app};
}

sub _keyring {
    my ($st) = @_;
    my $path = $st->{ingest}{keys};
    return undef unless defined $path && length $path;

    open my $fh, '<', $path
        or Carp::croak("Punk::Plugin::Observe: cannot read key file $path: $!");
    my @pairs;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*(?:#|$)/;
        my ($name, $token) = split /\s+/, $line, 2;
        next unless defined $token && length $token;
        push @pairs, $name, $token;
    }
    close $fh;
    return \@pairs;
}

sub _key_ok {
    my ($keys, $env) = @_;
    return 1 unless $keys && @$keys;
    my $r = Punk::Observe::Key::check($keys, $env->{HTTP_AUTHORIZATION}, undef);
    return $r->{ok} ? 1 : 0;
}

sub _persist {
    my ($st, $tenant, $signal, $body, $encoding, $out) = @_;

    my $json = ($encoding || '') eq 'json';
    my $doc  = $body;
    if ($json) {
        $doc = eval { File::Raw::JSON::file_json_decode($body) };
        return 0 unless $doc;
    }

    my $want = $st->{opts}{on_records} ? 1 : 0;
    my $store = store_for($st, $tenant);
    my $path  = $store ? $store->wal_path : '';

    my $r = eval {
        Punk::Observe::Ingest::decode_append(
            $path, $doc, $signal, $json ? 'json' : 'protobuf',
            1, '200000000', $want,
            $st->{arena} ? $st->{arena}{handle} : 0,
            $st->{limits}{rate_records} || 0,
            $st->{limits}{rate_bytes}   || 0);
    };
    if (!$r) {
        warn "Punk::Plugin::Observe: ingest failed: $@" if $@;
        return 0;
    }

    return 0 unless $r->{ok};

    if ($want && $r->{records}) {
        eval { $st->{opts}{on_records}->($tenant, $signal, $r->{records}) };
    }

    if (!$r->{appended}) {
        warn "Punk::Plugin::Observe: WAL append failed: $r->{errno}\n"
            if $r->{errno};
        return 0;
    }

    $st->{written} += $r->{n};

    $out->{rejected} = ($out->{rejected} || 0) + $r->{rejected}
        if ref $out eq 'HASH' && $r->{rejected};

    $store->seal_if_full($r->{bytes} || 0) if $store;
    return 1;
}

1;

__END__

=head1 NAME

Punk::Plugin::Observe - mount Punk::Observe in a Punk application

=head1 SYNOPSIS

    plugin 'Observe' => {
        prefix => '/observe',
        guard  => 'Web::Auth#observe_admin',       # required
        store  => '/var/lib/punk-observe',
        ingest => { prefix => '/v1', keys => '/etc/punk-observe/keys' },
        limits => { series => 1_000_000, rate_records => 50_000 },
    };

=head1 DESCRIPTION

Mounts the observability UI under a B<guarded scope> and, optionally, the
OTLP ingest endpoint beside it.

=head2 The guard is not optional

Registration croaks without one.

An unguarded mount is every log line the application has ever written, served
to anybody who finds the prefix. A loud failure at boot beats a silent hole
that nobody notices, so the failure is at registration rather than at the
first request.

Setting C<PUNK_OBSERVE_INSECURE> is the deliberate escape, named for this
distribution so that meaning it is possible and doing it by accident is not.

The UI is registered as an C<under> scope rather than a C<mount>. Under a
scope the guard covers every path beneath it including ones added later; a
mount with a guard on each route is the same thing right up until somebody
adds a route and forgets, and the failure mode of forgetting is an
unauthenticated page.

=head2 Ingest is a separate scope, in both directions

The ingest prefix sits outside the UI scope on purpose.

It is authenticated by B<key> and not by the UI guard, because an exporter
has no session. It is CSRF-exempt, because an exporter has no form token.

Both directions are bugs. A UI route that became CSRF-exempt by sharing this
scope would be a security hole; an ingest route that required a form token
would return 403 to every exporter in the world with a message about forms.

An ingest key cannot read the UI. There is no option to widen it: a key that
could do both leaks a whole installation the first time it is baked into a
container image, which is where ingest keys go.

=head2 Options

=over 4

=item C<prefix>

Where the UI mounts. Defaults to C</observe>.

=item C<guard>

Required. A coderef, or C<'Controller#action'>.

=item C<store>

The store root. Every path this distribution builds is rooted here.

=item C<tenant>

A constant tenant id, or a coderef resolving one. B<Defaults to a constant>,
so the self-hosted shape is the whole shape and the hosted one is a callback
through the same code. Whatever a resolver returns is validated before a byte
of it reaches a path - a resolver is host code, and host code that returns
C<../other> is a bug to catch rather than a value to trust.

A tenant id is never taken from anything a client sends.

=item C<ingest>

C<< { prefix => '/v1', keys => $path } >>. Omit it and no ingest endpoint is
registered at all.

=item C<limits>

C<rate_records> and C<rate_bytes> per second, C<series> for cardinality,
C<storage> in bytes, and C<attributes> for the indexed-attribute allowlist.

The rate limit is B<off> unless configured: a default rate limit on a
self-hosted box is a surprise in the wrong direction. The cardinality limit
B<has> a default, because a store with no cardinality limit is a store
waiting for one bad deploy.

C<rate_records> and C<rate_bytes> truncate the batch B<before it reaches the
log> and answer with an OTLP partial success naming what was dropped. That
ordering is the contract: a partial success means "I did not keep these", so
an exporter resending what it was told was rejected must not find those
records already stored.

The counters behind all of this live in a small shared page mapped at
registration, which is B<before the fork>. One mapped afterwards would be
private per worker, and the symptom is not a crash - it is a rate limit N
times what was configured and a status page showing whichever shard of the
traffic answered the request. Where the platform cannot share one, the status
page says so rather than presenting a fraction as a total.

=item C<limits> and what the status page can show

Two record counts appear on the status page and they answer different
questions. B<accepted> is what arrived, counted at ingest; B<records> is what
the store still holds. Retention makes the second smaller over time and a
limit makes it smaller immediately, so a gap between them is not an error.

The store cannot report the first. Refused data never reaches it, so a
receiver throwing every batch away and a receiver being sent nothing have
identical stored totals.

=item C<cache>

    cache => 0                                    # off
    cache => { dir => '/var/cache/observe',
               max_bytes => '1G' }

The dashboard chunk cache, B<on unless turned off>. A panel over twenty-four
hours re-scans twenty-four hours on every refresh, of which all but the last
few minutes has settled: this keeps the settled chunks so only the live tail
is computed. Measured on the demo's two-panel dashboard at C<range=24h>, a
refresh went from 9.6 seconds to 1.6.

A L<Punk::Cache> file store, because the point is that the workers share it -
a per-worker memory cache would compute every chunk once per worker and hold
as many copies. It lives in C<cache/> beside the data it summarises unless
C<dir> says otherwise, so moving a store takes its derived files with it, and
defaults to 256MB.

Every path through it degrades to the plain query: L<Punk::Cache> not
installed, an unwritable directory, a full disk and a corrupt entry all come
out as a slower answer rather than a broken panel. L<Punk::Observe::Cache>
carries what cannot be chunked and why.

The budgets the caller passed travel with every chunk. A panel asks for no row
ceiling, and a chunk run at the store's own default instead would truncate on
a busy hour and report the sum of a dozen capped scans as a figure somebody
had chosen.

=item C<warm>

    warm => 0                                     # off
    warm => { every => '@every 5m', depth => '7d',
              refresh => '2h', ttl => '8d',
              budget => 400, timeout => 20 }

Fills the cache above in the background, B<on unless turned off>. Without it
the first person to open a dashboard after a restart pays for the whole
window, because the cache fills as a side effect of answering. Measured on the
demo's 10GB store, a cold twenty-four-hour panel took 64 seconds and a warm
one 0.4.

It is a L<Punk::Queue> cron task like the other four, so it runs in a worker
pool and B<not> in the web server - a deployment without one gets the
uncached behaviour rather than an error. It needs the query cache, so
C<< cache => 0 >> turns it off too.

C<depth> is how far back to keep hot, clamped to C<retain>'s window where one
is configured: warming over data retention has deleted is work for an answer
that can never be right. C<refresh> is the newest window recomputed on every
pass rather than kept, which is where late telemetry lands. C<ttl> outlives
C<depth> deliberately, so an entry is not re-earned on a schedule.

C<budget> and C<timeout> bound one pass, because a pass over a busy store is
unbounded work and a job that can run for ever can hold a worker for ever. A
pass that stops resumes on the next tick. L<Punk::Observe::Warm> carries what
it walks and what it reports; C<punk-observe-warm> runs one pass by hand.

=item C<retain>

    retain => { keep => '7d' }              # hourly, at :17
    retain => { keep => '30d', at => '40 2 * * *' }
    retain => { keep => '48h', bytes => '2G' }
    retain => { keep => '7y' }              # what a production store keeps

Schedules retention on the host's queue. B<There is no default window>: absent
this option nothing is ever deleted, because a retention job with a silently
defaulted window is a deletion job. A C<keep> that does not parse is a boot
failure - the alternative is an operator who believes deletion is running
when nothing is.

C<keep> takes any duration the query language takes, up to and including
years: C<y> is exactly 365 days. A window past the last representable
instant - beyond roughly 584 years - is refused rather than wrapped, because
a wrapped window is a cutoff of I<now> and deletes the store.

C<bytes> is an optional budget over and above the window ('500M', '2G', or a
plain byte count): a store still past it after the time sweep loses its
oldest segments even inside the window, because a full disk loses everything
rather than the oldest hour. A size that does not parse is a boot failure,
for the same reason C<keep> is.

What it does when it runs: B<deletes>, never archives. Whole sealed segments
whose newest record is older than C<now - keep> are C<unlink>ed with their
index sidecars; the live log and any segment still holding one record inside
the window survive untouched, so C<keep> is a floor rather than an exact
edge. Nothing is copied anywhere first. A reader already holding a deleted
segment keeps reading it to the end - the primitive is C<unlink>, never
C<truncate>, and L<Punk::Observe::Retain> carries the reasons.

=item C<health_allow>

Hosts the outbound-URL policy should admit when a health target is saved and
when it is polled, as an arrayref. The policy refuses loopback, link-local
and private ranges by default - correct for a URL a stranger typed, and
exactly wrong for a self-hosted install watching services on its own network,
which is what the allowlist is for.

=item C<on_alert>

    on_alert => sub {
        my ($event) = @_;
        # app           the application class
        # tenant
        # rule          { id, name, query, op, threshold, for_ns, every_ns }
        # kind          firing | resolved | vanished | error
        # series        [ { series, kind, value, at, fired_at }, ... ]
        #               one entry, or many when a group delivered together
        # count
        # at            when this delivery became due (ns string)
        # path          "/observe/alerts/<id>" - the host owns its origin
        # delivery_key  idempotency token, per group per send
    },

The delivery seam, and the host's whole contribution to alerting: rules are
edited on the screen, evaluated by the cron this plugin registers on the
host's queue, and every notification arrives here. Webhook, email, pager -
delivery is the one thing the core cannot know, so the core does no outbound
HTTP at all; L<Punk::Observe::Target> is available for hosts that send to
URLs.

Values are B<raw> - nanoseconds where the query measured time - because
formatting belongs to the host. A C<die> is retried by the queue, five
attempts with backoff, and the terminal failure is a dead letter on the
group, visible, never dropped. Delivery is B<at least once>; C<delivery_key>
is the token for a host that wants exactly-once on its own side.

Absent, notifications are still recorded and marked; there is simply nobody
to tell.

B<The ordering rule>: alerting runs on the host's queue, so C<use
Punk::Plugin::Queue> and C<plugin 'Queue'> must come B<before> this plugin -
the same rule Punk-Mailer enforces, with the same loud boot failure when it
is missing. The registered cron is C<observe-evaluate>; pausing it through
the queue's controls survives deploys, because cron reconcile never resets
C<enabled>.

=item C<alerts>

Policy for the built-in alerting path, all optional:

    alerts => {
        every           => '@every 30s',  # the cron cadence - the resolution
        group_wait      => '30s',  # a group holds this long before its first
                                   # send: one bad deploy, one message
        repeat_interval => '15m',  # re-page a STILL-firing group; off absent
    };

Or the escape: a B<reader seam> - a coderef or hashref, as below - for a host
that keeps rules somewhere of its own. A host that supplies one keeps its own
evaluator too: no cron is registered for it, and C<on_alert> does not apply.
Rules are configuration with an owner, a review and a history, so they live
in the configuration database rather than in a telemetry store that retention
deletes from; F<sqitch/> is the schema.

    alerts => sub {
        # ONE argument, and it is the request - not ($id, $req). The
        # dashboards seam below takes its slug first; this one does not, and
        # reading it that way binds the request hashref to $id.
        my ($req) = @_;             # $req->{id} on /observe/alerts/:id
        return {
            rules    => [ { id, name, series, state, value, held } ],
            silences => [ { pattern, until, by, reason } ],
            events   => [ { series, to, at } ],     # optional
            can_edit => 1,
            to       => $now_ns,                    # optional
        };
    };

C<state> is one of C<ok>, C<pending>, C<firing>, C<stale> or C<error>, per
series rather than per rule - one state for a whole rule is the bug that makes
an alert resolve because a B<different> service recovered.

B<C<held> and C<value> are numbers, and the screen formats them.> C<held> is
how long the series has been in its current state, in B<nanoseconds>, rendered
as a duration; C<value> is the number the rule last compared, rendered with
C<%.4g> and no unit. A pre-formatted string does not survive either: C<"2m30s">
is read as the number 2 and drawn as two nanoseconds. A latency is therefore
worth converting to milliseconds before it is handed over, since nanoseconds
under C<%.4g> come out as C<2.911e+09>.

C<events> is the state history, and the screen draws a timeline from it. Each
entry is a transition: the series, the state it moved C<to>, and the instant
C<at> which it did, as nanoseconds. That is a row of C<alert_events> in the
shipped schema. Supply it and the timeline appears; omit it and the screen is
the table alone.

B<The timeline is drawn only from recorded transitions.> One inferred from
current state would be a straight line claiming the present has always been
the case - which is exactly the question a reader opens it to answer, so
answering it wrongly is worse than not answering it.

C<to> is where the timeline's right edge sits, defaulting to now. The last
band runs to it, because a state nobody has left is still in force.

=item C<dashboards>

The same shape for dashboards: a hashref or a coderef taking a slug, returning
C<title>, C<cols>, C<panels> and a C<list> of the others. A panel is an OQL
string with a title, validated at save time by the parser that will run it.

B<Panel bodies are deferred.> The page ships each panel's title and a
placeholder; the browser fetches every body - chart or table - from its own
fragment route, in parallel, and refreshes it every thirty seconds.
C<?full=1> renders everything with the page instead, which is also the
no-JavaScript path. A panel is addressed by its id, or by its position for a
reader whose panels carry none - give panels ids if reordering while a page
is open matters to you. The editor runs no panel queries at all: it renders
forms.

B<The argument order differs from C<alerts>, and always has.> A dashboard
reader is called as C<< ($slug, $req) >> - the slug first, because a
dashboard page is a request for one particular dashboard - while an alerts
reader takes only C<< ($req) >>. Getting them the same way round would mean
either passing a slug nothing uses or digging one out of the request, and
both are worse than the asymmetry.

B<Both seams are now overrides.> Absent, they read from the configuration
store this distribution ships - see C<db> - rather than meaning there are no
dashboards. To write as well as read, give a hashref instead of a coderef:

    dashboards => { read => \&r, write => \&w, delete => \&d }

A bare coderef is still a reader and still means what it did.

=item C<db>

Where the configuration lives: dashboards, panels, alert rules, silences. A
dsn, a hashref of L<Punk::Observe::Backend> options, an object answering to
C<dbh> and C<migrate>, or C<0> to have none.

Absent, it is SQLite in a file called F<config.db> beside C<store> - so a
self-hosted installation has dashboards without deciding anything. With no
C<store> either there is nowhere obvious to put it and there is no default,
because guessing a path in the working directory is worse than having none.

The schema is migrated at registration, in every worker. That is idempotent
and locked, so it is a version check that occasionally does work.

=item C<identity>

A coderef given the request, returning a stable opaque string for whoever is
looking, or undef. Optional, and there is no user model here - the guard
decides who may look and this only says who they are, for the state that is
per viewer rather than per installation.

Whatever it returns is used as a key and never rendered, so an application
keying on an email address does not put one on a page. Absent, per-viewer
state lives in the browser and is per browser.

=item C<editing>

Not an option. The editor is at C<< <prefix>/dashboards/:slug/edit >> and
C<< <prefix>/dashboards/new >>, and both are the ordinary dashboard page's
data rendered through a different template - so a panel shown on one is the
same panel the other saved, and there is no second reader for them to
disagree through.

The forms C<POST> to six routes, all registered only when C<writable>:

    POST <prefix>/dashboards                       create
    POST <prefix>/dashboards/:slug                 update
    POST <prefix>/dashboards/:slug/delete
    POST <prefix>/dashboards/:slug/panels          add a panel
    POST <prefix>/dashboards/:slug/panels/save     save the whole table
    POST <prefix>/dashboards/:slug/panels/:id      update one
    POST <prefix>/dashboards/:slug/panels/:id/delete

A successful write answers C<303> to the reader's own page, so a reload
cannot re-submit and the editor shows what happened rather than what it hoped
would. A refused one comes back as the form, C<400>, with the reason against
the field it is about.

=item C<writable>

C<0> to mount read-only. Editing is otherwise on when there is somewhere to
write and the application has turned on L<Punk::CSRF> - a write route without
a token is forgeable from another origin, and this plugin cannot enable CSRF
for the host because the token needs a session only the application can hold.
When it is off the write routes are B<not registered at all>, and the screens
say why rather than showing a button that does not work.

=item C<stats>

B<Discouraged.> It predates the built-in configuration store and the health
targets, which between them cover what it was for - a number of your own on
the status page is better expressed as a health check or a dashboard panel,
both of which have history and neither of which can overwrite C<error>.
It keeps working; a callback that dies now warns instead of vanishing.

A coderef called as C<< ($c, $page_name, $store) >> on B<every> screen, whose
returned hashref is merged over the template variables. It is a blunt
instrument: the merge is flat and last-writer-wins, so it can overwrite
C<error> or C<rows> as easily as add a number, and it runs after the decision
about whether to load the charting library, so a C<*_plot> key it returns
will not draw.

=item C<root>

The template and asset directory, if you are shipping your own.

=item C<seal_bytes> / C<max_rows>

Passed to L<Punk::Observe::Store> as given.

=item C<on_records>

A coderef called as C<< ($tenant, $signal, $records) >> after a batch is
persisted. Materialising the records costs something, so this is off unless
asked for.

=back

=head2 What each limit does at its cap

They fail three different ways, and treating them as one limit is the
mistake:

=over 4

=item Ingest rate

Returns an OTLP B<partial success naming the rejected count>, never a bare
429. A 429 makes the exporter re-send the whole batch, forever, at the moment
the server is already under pressure - the limit becomes an amplifier.

The limiter covers the ingest prefix and nothing else. Rate-limiting a health
endpoint takes the box out of a load balancer under exactly the load the
limiter exists for.

=item Cardinality

The B<new> series is dropped, counted, and surfaced. An existing series is
never evicted to admit a new one: that converts a cardinality problem into
data loss on the exact series somebody has open in a dashboard.

The counter lives in an arena mapped B<before> the fork, so the limit is per
pool. One mapped afterwards is private per worker, and the symptom is a limit
silently N times what was configured.

=item Storage bytes

The retention job B<shortens retention>. Writes are never refused. A store
over its byte budget should lose old data; it must not lose the incident
happening now.

=back

=head2 The allowlist matters more than any of the numbers

Logs and spans carry unbounded attributes, and only the configured set
becomes an index dimension. The rest stay in the record and are reachable by
a residual filter, so nothing is lost - it is just slower to find.

Without it, one service putting a request id in a resource attribute takes
the store down. The overflow counter B<names the attribute>, because the
person who hits this first is a self-hoster with no support contract and no
dashboard telling them which one did it.

=head1 SEE ALSO

L<Punk::Observe>, L<Punk::Observe::Tenant>, L<Punk::Observe::Key>,
L<Punk::Observe::Limit>

=cut
