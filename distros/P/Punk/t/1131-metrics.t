#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Plugin::Metrics;

# A Prometheus /metrics endpoint.
#
# The gate is CARDINALITY. A counter labelled with the REQUEST path is the
# classic monitoring outage - /users/1, /users/2 and a million more each
# becoming their own time series until the scrape target takes the monitoring
# system down with it. Punk knows every route pattern at to_app, so the label
# set is bounded by construction, and that is what these assert.

our $COLLECT = {};

{
    package MetApp;
    use Punk;

    plugin 'Metrics' => { collect => sub { $COLLECT } };

    get  '/'          => sub { $_[0]->text('home') };
    get  '/users/:id' => sub { $_[0]->text('user') };
    post '/orders'    => sub { $_[0]->text('order') };
    get  '/boom'      => sub { die "no\n" };
}

my $app = MetApp->to_app;
my $punk = MetApp->punk_app;

sub hit {
    my (%o) = @_;
    return $app->({ REQUEST_METHOD => $o{method} || 'GET',
                    PATH_INFO => $o{path}, SCRIPT_NAME => '',
                    QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
                    'psgi.url_scheme' => 'http', 'psgi.input' => undef,
                    'psgi.errors' => \*STDERR, %{ $o{env} || {} } });
}
sub scrape { return hit(path => '/metrics')->[2][0] }
sub lines  { my $re = shift; return grep { /$re/ } split /\n/, scrape() }

# ---- THE GATE: the label set is the route table, not the request path -------
{
    Punk::Plugin::Metrics->_reset;
    hit(path => "/users/$_") for 1 .. 50;

    my @u = lines(qr/^http_requests_total\{.*route="/);
    is(scalar @u, 1,
        'THE GATE: fifty requests to fifty different ids produce ONE time '
      . 'series, because the label is the DECLARED route. Labelling with the '
      . 'request path is how a bounded dimension becomes unbounded and how a '
      . 'monitoring system gets taken down by the thing monitoring it');
    like($u[0], qr/route="\/users\/:id"/,
        '...labelled with the pattern, not with any of the fifty paths');
    like($u[0], qr/\} 50$/, '...and it counted all fifty');

    unlike(scrape(), qr{route="/users/\d},
        'and no id appears anywhere in the document');
}

# ---- the pair: distinct routes are still distinct ---------------------------
#
# Without this, "collapse everything into one series" would pass the gate.
{
    Punk::Plugin::Metrics->_reset;
    hit(path => '/');
    hit(path => '/users/1');
    hit(path => '/orders', method => 'POST');

    my @all = lines(qr/^http_requests_total\{/);
    is(scalar @all, 3,
        'three different routes are three series - the gate above is a bound '
      . 'on cardinality, not a collapse of it');
    is(scalar(grep { /method="POST".*route="\/orders"/ } @all), 1,
        'and the method is a label, so GET and POST on one path are separate');
}

# ---- a 404 has no route to name ---------------------------------------------
{
    Punk::Plugin::Metrics->_reset;
    hit(path => "/no/such/$_") for 1 .. 20;

    my @o = lines(qr/^http_requests_total\{/);
    is(scalar @o, 1, 'twenty different unmatched paths are ONE series');
    like($o[0], qr/route="<other>".*status="404".*\} 20$/,
        '...labelled <other>, because a 404 has no route by definition and '
      . 'giving it the request path is exactly the unbounded case again');
}

# ---- status is a label, and an error is a status ----------------------------
{
    Punk::Plugin::Metrics->_reset;
    hit(path => '/');
    hit(path => '/boom');

    like(scrape(), qr/route="\/",status="200"/, 'a served route reports 200');
    like(scrape(), qr/route="\/boom",status="500"/,
        'and a handler that died reports 500 - the observer fires on every '
      . 'path, so an exporter does not go blind exactly when it matters');
}

# ---- the histogram ----------------------------------------------------------
{
    Punk::Plugin::Metrics->_reset;
    hit(path => '/') for 1 .. 3;
    my $doc = scrape();

    my @b = ($doc =~ /_bucket\{[^}]*le="([^"]+)"\}/g);
    my @want = (Punk::Plugin::Metrics->buckets, '+Inf');
    # Compared at a fixed precision rather than as numbers, because on a
    # long-double or quadmath perl they are not the same number twice. The
    # bucket bound is a C double widened to the wider NV, which keeps the
    # error the double had - 0.00050000000000000001 - while the label parsed
    # back out of the document is that wider NV's own nearest value, 0.0005.
    # Both are the bucket; only one is what the C literal became.
    my $near = sub { map { sprintf '%.10g', $_ } @_ };
    is_deeply([ $near->(grep { $_ ne '+Inf' } @b) ],
              [ $near->(Punk::Plugin::Metrics->buckets) ],
        'the buckets are the documented set - changing them later invalidates '
      . 'every histogram already recorded, so they are asserted rather than '
      . 'left to drift');

    like($doc, qr/_bucket\{[^}]*le="\+Inf"\} 3/,
        'the +Inf bucket holds every observation');
    like($doc, qr/_count\{[^}]*\} 3/, 'and _count agrees with it');
    like($doc, qr/_sum\{[^}]*\} [\d.]+/, 'with a _sum in seconds');

    # Cumulative, which is what a Prometheus histogram means.
    my @counts = ($doc =~ /_bucket\{[^}]*le="[^"]+"\} (\d+)/g);
    my $sorted = 1;
    for my $i (1 .. $#counts) { $sorted = 0 if $counts[$i] < $counts[$i - 1] }
    ok($sorted,
        'buckets are cumulative and non-decreasing - a request lands in its '
      . 'own bucket AND every wider one');

    is(scalar(grep { /le="0.0005"/ } split /\n/, $doc), 1,
        'the first bucket is half a millisecond, not the Prometheus default '
      . 'of 5ms - Punk dispatches in microseconds, so a 5ms first bucket '
      . 'would hold every request and answer nothing');
}

# ---- the scrape does not count itself ---------------------------------------
{
    Punk::Plugin::Metrics->_reset;
    hit(path => '/');
    scrape() for 1 .. 5;

    unlike(scrape(), qr{route="/metrics"},
        'six scrapes later there is still no /metrics series - a series whose '
      . 'only traffic is Prometheus asking about it is noise in every panel');

    like(scrape(), qr/^http_requests_in_flight\{[^}]*\} 0$/m,
        'and in-flight reads 0 DURING a scrape. The scrape is itself in '
      . 'flight while it renders, so counting it would give an idle server a '
      . 'permanent floor of one, on every dashboard, for ever');
}

# ---- in-flight actually moves -----------------------------------------------
#
# The pair for the assertion above: "always zero" would pass it alone.
{
    Punk::Plugin::Metrics->_reset;
    my $seen;
    {
        package FlightApp;
        use Punk;
        plugin 'Metrics' => { path => '/m2' };
        get '/deep' => sub {
            my ($c) = @_;
            $seen = Punk::Plugin::Metrics->_render($c->app);
            $c->text('ok');
        };
    }
    my $fapp = FlightApp->to_app;
    $fapp->({ REQUEST_METHOD => 'GET', PATH_INFO => '/deep', SCRIPT_NAME => '',
              QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
              'psgi.url_scheme' => 'http', 'psgi.input' => undef,
              'psgi.errors' => \*STDERR });

    like($seen, qr/^http_requests_in_flight\{[^}]*\} 1$/m,
        'a request rendering the document from inside itself sees 1 in '
      . 'flight - the gauge moves, so the zero above is an exclusion rather '
      . 'than a gauge that never worked');
}

# ---- the worker label -------------------------------------------------------
{
    Punk::Plugin::Metrics->_reset;
    hit(path => '/');
    like(scrape(), qr/worker="$$"/,
        'every series carries a worker label. A scrape hits ONE worker of a '
      . 'prefork pool, so without it a graph shows one Nth of the traffic and '
      . 'a different Nth each scrape - noise that looks like data');
}

# ---- the exposition format --------------------------------------------------
{
    Punk::Plugin::Metrics->_reset;
    hit(path => '/');
    my $r = hit(path => '/metrics');
    my %h = @{ $r->[1] };

    is($r->[0], 200, 'the scrape is a 200');
    is($h{'Content-Type'}, 'text/plain; version=0.0.4; charset=utf-8',
        'in the Prometheus text exposition content type');
    is($h{'Cache-Control'}, 'no-store',
        'and uncacheable - a cached scrape is a graph of the past');

    my $doc = $r->[2][0];
    like($doc, qr/^# HELP http_requests_total /m, 'every metric has a HELP');
    like($doc, qr/^# TYPE http_requests_total counter$/m, '...and a TYPE');
    like($doc, qr/^# TYPE http_request_duration_seconds histogram$/m,
        'the histogram is declared as one');
    like($doc, qr/\n$/, 'and the document ends in a newline');
}

# ---- stability: two scrapes of the same state are byte identical ------------
{
    Punk::Plugin::Metrics->_reset;
    hit(path => '/');
    hit(path => '/users/9');
    hit(path => '/orders', method => 'POST');
    my $a = scrape();
    my $b = scrape();
    is($a, $b,
        'two scrapes of unchanged state are byte identical - the series are '
      . 'sorted, so a diff of two documents shows what changed rather than '
      . 'what moved');
}

# ---- collect: the application adds its own gauges ---------------------------
{
    Punk::Plugin::Metrics->_reset;
    local $COLLECT = { queue_depth => 12, queue_workers => 3 };
    hit(path => '/');
    my $doc = scrape();

    like($doc, qr/^# TYPE queue_depth gauge$/m, 'a collected value is a gauge');
    like($doc, qr/^queue_depth\{worker="$$"\} 12$/m, '...with its value');
    like($doc, qr/^queue_workers\{worker="$$"\} 3$/m, '...and the others');
}

# ---- a bad metric name is dropped, not emitted ------------------------------
#
# One invalid name does not break one series: it makes the WHOLE scrape
# unparseable, and every metric the application has disappears at once.
{
    Punk::Plugin::Metrics->_reset;
    local $COLLECT = { 'not a name' => 1, '9lives' => 2, good_one => 3 };
    hit(path => '/');
    my $doc = scrape();

    unlike($doc, qr/not a name/, 'a name with spaces is dropped');
    unlike($doc, qr/^9lives/m, 'so is one starting with a digit');
    like($doc, qr/^good_one\{worker="$$"\} 3$/m,
        'while the valid one is still emitted - one bad name must not take '
      . 'the entire scrape down with it');
}

# ---- a collect callback that dies does not break the scrape -----------------
{
    Punk::Plugin::Metrics->_reset;
    {
        package DyingApp;
        use Punk;
        plugin 'Metrics' => { path => '/m3',
                              collect => sub { die "the queue is gone\n" } };
        get '/x' => sub { $_[0]->text('x') };
    }
    my $dapp = DyingApp->to_app;
    my $d = sub {
        $dapp->({ REQUEST_METHOD => 'GET', PATH_INFO => $_[0],
                  SCRIPT_NAME => '', QUERY_STRING => '', SERVER_NAME => 'l',
                  SERVER_PORT => 80, 'psgi.url_scheme' => 'http',
                  'psgi.input' => undef, 'psgi.errors' => \*STDERR });
    };
    $d->('/x');
    my $r = $d->('/m3');
    is($r->[0], 200,
        'a collect callback that dies still leaves a scrapeable document - '
      . 'losing one optional gauge must not lose the core metrics too');
    like($r->[2][0], qr/^http_requests_total\{/m, '...with the core metrics');
}

# ---- the options that are refused -------------------------------------------
{
    my $err = do {
        local $@;
        eval "package BadMet; use Punk; plugin 'Metrics' => { collect => 'no' }; 1";
        $@;
    };
    like($err, qr/`collect` takes a coderef/,
        'a collect that is not a coderef is refused at boot');
}

# ---- out of the sitemap -----------------------------------------------------
{
    {
        package SiteMet;
        use Punk;
        plugin 'Sitemap' => { base => 'https://example.com' };
        plugin 'Metrics' => { path => '/m4' };
        get '/' => sub { $_[0]->text('h') };
    }
    SiteMet->to_app;
    my @p = Punk::Plugin::Sitemap->_paths(SiteMet->punk_app);
    is_deeply(\@p, ['/'],
        'a scrape target is not a page, so it is out of the sitemap');
}

# ---- the cache gauges, and the streaming status -----------------------------
#
# Both were wrong when first written, which is why they are asserted rather
# than described: the app's `cache` slot is a HASH of named caches, not a
# cache, so calling ->stats on it was a 500 on every scrape.
{
    {
        package CacheMet;
        use Punk;
        cache 'memory', max_bytes => '1M';
        plugin 'Metrics' => { path => '/m5' };
        get '/x' => sub { $_[0]->text('x') };
        get '/stream' => sub {
            return sub {
                my $w = shift;
                $w->write([ 200, [ 'Content-Type', 'text/plain' ], ['x'] ]);
            };
        };
    }
    my $capp = CacheMet->to_app;
    my $c = sub {
        $capp->({ REQUEST_METHOD => 'GET', PATH_INFO => $_[0],
                  SCRIPT_NAME => '', QUERY_STRING => '', SERVER_NAME => 'l',
                  SERVER_PORT => 80, 'psgi.url_scheme' => 'http',
                  'psgi.streaming' => 1, 'psgi.input' => undef,
                  'psgi.errors' => \*STDERR });
    };

    Punk::Plugin::Metrics->_reset;
    $c->('/x');
    $c->('/stream');
    my $r = $c->('/m5');
    my $doc = $r->[2][0];

    is($r->[0], 200, 'a scrape with a cache configured is still a 200');
    like($doc, qr/^punk_cache_hits\{cache="default",worker="$$"\} \d+$/m,
        'the cache reports its counters, labelled with the cache NAME - the '
      . 'app holds a hash of named caches, so every one of them is reported');
    like($doc, qr/^punk_cache_pool\{cache="default"/m,
        '...including pool, which says whether a shared invalidation bus '
      . 'exists at all');

    like($doc, qr/route="\/stream",status="-"/,
        'a streaming response reports status "-" rather than a guessed 200 - '
      . 'there is no status to read, and a guess would put a 200 on a graph '
      . 'that never happened');
}

done_testing;
