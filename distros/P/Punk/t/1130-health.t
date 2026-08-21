#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Punk::Plugin::Health;

# Liveness and readiness are different questions, and the plugin exists
# because hand-rolled probes collapse them into one.
#
# The gate is the separation: /healthz must keep answering 200 while every
# dependency is down, because failing it RESTARTS THE WORKER, and restarting a
# worker does not fix a database. /readyz is the one that must notice.

our $DB_UP    = 1;
our $CACHE_UP = 1;
our $CALLS    = 0;

{
    package HealthApp;
    use Punk;

    plugin 'Health' => {
        version => '1.4.2',
        detail => 1,
        ttl    => 0,          # no caching: the caching is tested separately
        checks => {
            db    => sub { $CALLS++; $DB_UP    or die "connect failed\n"; 1 },
            cache => sub { $CALLS++; $CACHE_UP ? 1 : 0 },
        },
    };

    get '/' => sub { $_[0]->text('home') };
}

my $app = HealthApp->to_app;
my $punk = HealthApp->punk_app;

sub hit {
    my (%o) = @_;
    return $app->({ REQUEST_METHOD => $o{method} || 'GET',
                    PATH_INFO => $o{path}, SCRIPT_NAME => '',
                    QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
                    'psgi.url_scheme' => 'http', 'psgi.input' => undef,
                    'psgi.errors' => \*STDERR, %{ $o{env} || {} } });
}
sub hdr  { my %h = @{ $_[0][1] }; return \%h }
sub body { return $_[0][2][0] }

# ---- the endpoints exist and say the ordinary thing --------------------------
{
    my $r = hit(path => '/healthz');
    is($r->[0], 200, '/healthz answers');
    like(body($r), qr/"status":"ok"/, '...with a status');
    is(hdr($r)->{'Content-Type'}, 'application/json', '...as JSON');

    my $y = hit(path => '/readyz');
    is($y->[0], 200, '/readyz answers 200 while everything is up');
    like(body($y), qr/"status":"ok"/, '...and says ok');
}

# ---- GATE: liveness must not notice a dependency ------------------------------
#
# The assertion in PAIRS, because "liveness always returns 200" would pass the
# first half on its own. The point is that the two endpoints disagree, at the
# same moment, about the same broken dependency.
{
    local $DB_UP = 0;

    my $live = hit(path => '/healthz');
    is($live->[0], 200,
        'THE GATE: liveness still answers 200 with the database down - '
      . 'failing it would get this worker KILLED AND RESTARTED, which does '
      . 'not fix a database and removes capacity when load is highest');
    unlike(body($live), qr/\bdb\b/,
        '...and does not even mention the check, because it does not have '
      . 'the check list - the separation is by construction, not by '
      . 'remembering');

    my $ready = hit(path => '/readyz');
    is($ready->[0], 503,
        '...while readiness answers 503 to the same broken dependency, which '
      . 'takes this worker out of the pool WITHOUT killing it');
    like(body($ready), qr/"status":"unready"/, '...and says unready');
}

# ---- a check that returns false, and one that dies --------------------------
{
    {
        local $CACHE_UP = 0;
        my ($ok, $detail) = Punk::Plugin::Health->_ready($punk);
        is($ok, 0, 'a check returning false is not ready');
        like($detail, qr/"cache":\{"ok":false/, '...and is reported false');
        unlike($detail, qr/"cache":\{[^}]*"why"/,
            '...with no reason, because returning false gave none');
    }
    {
        local $DB_UP = 0;
        my ($ok, $detail) = Punk::Plugin::Health->_ready($punk);
        is($ok, 0, 'a check that DIES is not ready rather than a 500 - a '
                 . 'readiness probe exists to be told no');
        like($detail, qr/"db":\{[^}]*"why":"connect failed"/,
            '...and the exception is the reason, with the newline trimmed');
    }
}

# ---- the detail is off by default -------------------------------------------
#
# Health output names an application's internal dependencies and these
# endpoints are unauthenticated, because a probe cannot hold a credential.
{
    {
        package QuietApp;
        use Punk;
        plugin 'Health' => { version => 'v-secret',
                             checks => { db => sub { 0 } } };
    }
    my $qapp = QuietApp->to_app;
    my $q = sub {
        $qapp->({ REQUEST_METHOD => 'GET', PATH_INFO => $_[0],
                  SCRIPT_NAME => '', QUERY_STRING => '', SERVER_NAME => 'l',
                  SERVER_PORT => 80, 'psgi.url_scheme' => 'http',
                  'psgi.input' => undef, 'psgi.errors' => \*STDERR });
    };

    my $r = $q->('/readyz');
    is($r->[0], 503, 'a failing check is still a 503 without detail');
    is($r->[2][0], '{"status":"unready"}',
        'but the body is bare - naming your dependencies to an '
      . 'unauthenticated endpoint is a disclosure, so the detail is opt-in');
    unlike($r->[2][0], qr/v-secret/,
        '...and the version is not leaked either');

    like(body($q->('/healthz')), qr/"status":"ok"/,
        'liveness is bare too, and still ok');
}

# ---- caching, and the pid stamp ---------------------------------------------
{
    {
        package CachedApp;
        use Punk;
        plugin 'Health' => { ttl => 30, checks => { n => sub { $CALLS++; 1 } } };
    }
    my $capp = CachedApp->to_app;
    my $cpunk = CachedApp->punk_app;
    my $c = sub {
        $capp->({ REQUEST_METHOD => 'GET', PATH_INFO => '/readyz',
                  SCRIPT_NAME => '', QUERY_STRING => '', SERVER_NAME => 'l',
                  SERVER_PORT => 80, 'psgi.url_scheme' => 'http',
                  'psgi.input' => undef, 'psgi.errors' => \*STDERR });
    };

    local $CALLS = 0;
    $c->() for 1 .. 25;
    is($CALLS, 1,
        'twenty-five probes inside the ttl run the checks ONCE - a probe '
      . 'every 100ms must not become load in its own right');

    Punk::Plugin::Health->_uncache($cpunk);
    $c->();
    is($CALLS, 2, 'and the checks run again once the answer is dropped');

    # The pid stamp: a worker that forked after an answer was computed must
    # not serve its parent's verdict about a connection it does not hold.
    $c->();
    my $before = $CALLS;
    my $pid = open(my $fh, '-|');
    if (defined $pid && !$pid) {           # child
        $CALLS = 0;
        $c->();
        print "$CALLS\n";
        exit 0;
    }
    my $in_child = <$fh>;
    close $fh;
    chomp $in_child if defined $in_child;
    is($in_child, 1,
        'a FORKED worker recomputes rather than serving the answer its '
      . 'parent cached - the pid is stamped on it, because otherwise a whole '
      . 'pool agrees about a dependency only one of them ever contacted');
    is($CALLS, $before, '...and the parent is unaffected');
}

# ---- the budget stops further checks being started --------------------------
#
# It cannot interrupt one already blocked in a driver - nothing single
# threaded can - so what is asserted is what it actually does.
{
    {
        package SlowApp;
        use Punk;
        plugin 'Health' => {
            detail  => 1,
            ttl     => 0,
            timeout => 0.05,
            checks  => {
                a_slow => sub { Time::HiRes::sleep(0.12); 1 },
                b_next => sub { $CALLS++; 1 },
            },
        };
    }
    SlowApp->to_app;
    local $CALLS = 0;
    my ($ok, $detail) = Punk::Plugin::Health->_ready(SlowApp->punk_app);

    is($ok, 0, 'a pass that overruns its budget answers unready');
    is($CALLS, 0,
        'and the check after the slow one is never STARTED - which is what a '
      . 'budget can do, as against interrupting one already blocked');
    like($detail, qr/"b_next":\{"ok":false,"skipped":true/,
        '...reported as skipped rather than as a failure it never had');
    like($detail, qr/"a_slow":\{"ok":true/,
        '...while the one that did run reports what it returned');
}

# ---- an application with no checks ------------------------------------------
{
    {
        package BareApp;
        use Punk;
        plugin 'Health' => {};
    }
    my $bapp = BareApp->to_app;
    my $b = sub {
        $bapp->({ REQUEST_METHOD => 'GET', PATH_INFO => $_[0],
                  SCRIPT_NAME => '', QUERY_STRING => '', SERVER_NAME => 'l',
                  SERVER_PORT => 80, 'psgi.url_scheme' => 'http',
                  'psgi.input' => undef, 'psgi.errors' => \*STDERR });
    };
    is($b->('/healthz')->[0], 200, 'no checks configured: liveness is 200');
    is($b->('/readyz')->[0], 200,
        'and readiness is 200 - nothing was asked, so nothing said no');
}

# ---- the paths, and the options ---------------------------------------------
{
    is_deeply([ sort +Punk::Plugin::Health->paths($punk) ],
              [ '/healthz', '/readyz' ],
        'the plugin names the paths it serves, so an observer keeping '
      . 'metrics can skip them - it can only skip what it can name');

    {
        package OneApp;
        use Punk;
        plugin 'Health' => { liveness => '/alive', readiness => undef };
    }
    OneApp->to_app;
    is_deeply([ Punk::Plugin::Health->paths(OneApp->punk_app) ], [ '/alive' ],
        'a path can be renamed, and an explicit undef disables that '
      . 'endpoint for a platform that only probes one of them');
}

# ---- no-store, and out of the sitemap ---------------------------------------
{
    is(hdr(hit(path => '/healthz'))->{'Cache-Control'}, 'no-store',
        'a probe answer is never cacheable - a cached 200 is a health check '
      . 'reporting the past');
    is(hdr(hit(path => '/readyz'))->{'Cache-Control'}, 'no-store',
        '...both of them');
}

# ---- the options that are refused -------------------------------------------
{
    my $bad = sub {
        my ($opts) = @_;
        my $pkg = "BadApp" . int(rand 1e9);
        local $@;
        eval "package $pkg; use Punk; plugin 'Health' => $opts; 1";
        return $@;
    };
    like($bad->("{ checks => { db => 'not a sub' } }"), qr/not a coderef/,
        'a check that is not a coderef is refused at boot, naming it');
    like($bad->("{ timeout => 0 }"), qr/must be positive/,
        'a zero budget is refused - it would report unready always');
    like($bad->("{ ttl => -1 }"), qr/cannot be negative/,
        'and a negative ttl is refused');
}

# ---- the SYNOPSIS, run --------------------------------------------------------
#
# The documented database check, executed against a real SQLite handle rather
# than asserted to be plausible. An example in a SYNOPSIS is a claim, and this
# one was wrong twice before it was run: `dbh` lives on the BACKEND, not on
# the model, and `database` takes `dsn => ...` rather than a bare string.
SKIP: {
    eval { require DBI; require DBD::SQLite; 1 }
        or skip 'DBI + DBD::SQLite required', 4;

    {
        package T::Ping;
        BEGIN { $INC{'T/Ping.pm'} = 1 }
        use Punk::Model;
        table 'ping';
        field id => { type => 'integer', primary => 1 };
    }
    {
        package SynApp;
        use Punk;
        database dsn => 'dbi:SQLite:dbname=:memory:';
        model 'T::Ping';
        plugin 'Health' => {
            version => '1.4.2',
            detail  => 1,
            ttl     => 0,
            checks  => {
                db => sub {
                    my ($c) = @_;
                    $c->model('T::Ping')->backend->dbh->do('SELECT 1');
                    1;
                },
            },
        };
    }
    my $sapp = SynApp->to_app;
    my $s = sub {
        $sapp->({ REQUEST_METHOD => 'GET', PATH_INFO => $_[0],
                  SCRIPT_NAME => '', QUERY_STRING => '', SERVER_NAME => 'l',
                  SERVER_PORT => 80, 'psgi.url_scheme' => 'http',
                  'psgi.input' => undef, 'psgi.errors' => \*STDERR });
    };

    my $live = $s->('/healthz');
    is($live->[0], 200, 'the SYNOPSIS liveness answers 200');
    is($live->[2][0], '{"status":"ok","version":"1.4.2"}',
        '...with exactly the body the SYNOPSIS shows - a documented example '
      . 'is a claim, and this one is checked rather than described');

    my $ready = $s->('/readyz');
    is($ready->[0], 200, 'and the documented db check really round-trips');
    like($ready->[2][0],
         qr/^\{"status":"ok","version":"1\.4\.2","checks":\{"db":\{"ok":true,"ms":[\d.]+\}\}\}$/,
        '...reporting the shape the SYNOPSIS shows');
}

done_testing;
