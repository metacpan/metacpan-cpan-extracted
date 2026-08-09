#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;

# the inline app packages `use Punk` at compile time, so this guard
# must run during compilation too - a runtime skip_all would be too late
BEGIN {
    unless (eval { require Punk; 1 }) {
        require Test::More;
        Test::More::plan(skip_all => 'Punk required');
    }
}
plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

my $file = queue_file();
my $DSN = "dbi:SQLite:dbname=$file";

{
    package ApiApp;
    use Punk;
    use Punk::Plugin::Queue;
    task('t.ok'   => sub { 'fine' });
    task('t.boom' => sub { die "x\n" });
    plugin 'Queue' => {
        dsn   => $DSN,
        admin => { prefix => '/q', guard => sub { return } },
    };
}

my $app = ApiApp->to_app;
my $q = ApiApp::queue();

require File::Raw::JSON;
sub jdec { File::Raw::JSON::file_json_decode($_[0][2][0]) }
sub hit_api {
    my (%o) = @_;
    my $body = $o{body} // '';
    open my $in, '<', \$body or die $!;
    return $app->({
        REQUEST_METHOD => $o{method} // 'GET',
        PATH_INFO      => $o{path},
        QUERY_STRING   => $o{query} // '',
        CONTENT_TYPE   => $o{type} // ($body ne '' ? 'application/json' : ''),
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
        %{ $o{env} // {} },
    });
}

# fixtures: three jobs in known states, a worker
my $j1 = $q->enqueue('t.ok', [1], queue => 'a', priority => 5);
my $j2 = $q->enqueue('t.boom', [], queue => 'b', attempts => 1);
my $j3 = $q->enqueue('t.ok', [3], queue => 'a');
$q->perform($q->dequeue(queues => 'b'));           # j2 fails
my $wid = $q->backend->register_worker(0, { role => 'child' });

# ---- the Funky.Table wire protocol ------------------------------------------

{
    my $res = hit_api(path => '/q/api/jobs',
        query => 'draw=7&page=1&limit=2');
    is($res->[0], 200, 'jobs 200');
    my $r = jdec($res);
    is($r->{draw}, 7, 'draw echoed back');
    is($r->{total}, 3, 'total is the full count');
    is(scalar @{ $r->{data} }, 2, 'limit maps to page size');
    ok(exists $r->{data}[0]{id}, 'rows carry id - Funky selection needs it');

    # page 2
    $res = hit_api(path => '/q/api/jobs', query => 'page=2&limit=2');
    is(scalar @{ jdec($res)->{data} }, 1, 'page maps to offset');

    # the filter vocabulary, identical to the CLI's
    $res = hit_api(path => '/q/api/jobs', query => 'queue=a');
    is(jdec($res)->{total}, 2, 'queue filter');
    $res = hit_api(path => '/q/api/jobs', query => 'state=failed');
    is(jdec($res)->{total}, 1, 'state filter');

    # sort: JSON [{column,dir}], whitelisted
    my $sort = '%5B%7B%22column%22%3A%22priority%22%2C%22dir%22%3A%22desc%22%7D%5D';
    $res = hit_api(path => '/q/api/jobs', query => "sort=$sort");
    is(jdec($res)->{data}[0]{id}, $j1, 'sort by priority desc');

    my $bad = '%5B%7B%22column%22%3A%22evil%22%2C%22dir%22%3A%22asc%22%7D%5D';
    $res = hit_api(path => '/q/api/jobs', query => "sort=$bad");
    is($res->[0], 400, 'an unknown sort column is a clean 400');
    like(jdec($res)->{error}, qr/cannot sort/, 'with the reason');

    # search: the box on every table filters server-side, not just
    # highlights the page it is looking at
    $res = hit_api(path => '/q/api/jobs', query => 'search=boom');
    is(jdec($res)->{total}, 1, 'jobs search filters');
    $res = hit_api(path => '/q/api/jobs', query => 'search=BOOM');
    is(jdec($res)->{total}, 1, 'case-insensitively');
    $res = hit_api(path => '/q/api/jobs', query => 'search=t.&queue=a');
    is(jdec($res)->{total}, 2, 'and combines with the filters');
    $res = hit_api(path => '/q/api/workers', query => 'search=child');
    is(jdec($res)->{total}, 1, 'workers search');
    $res = hit_api(path => '/q/api/workers', query => 'search=zzz');
    is(jdec($res)->{total}, 0, 'workers search misses cleanly');
}

# ---- job detail with parents ------------------------------------------------

{
    my $child = $q->enqueue('t.ok', [], parents => [$j1]);
    my $res = hit_api(path => "/q/api/jobs/$child");
    is($res->[0], 200, 'job detail 200');
    is_deeply(jdec($res)->{parents}, [$j1], 'parents included for the UI');

    $res = hit_api(path => '/q/api/jobs/999999');
    is($res->[0], 404, 'missing job is 404');

    # the job's log: lifecycle rows plus whatever the task wrote (j2 is
    # the performed one - claimed, then its single attempt failed)
    $res = hit_api(path => "/q/api/jobs/$j2/log");
    is($res->[0], 200, 'job log 200');
    my $l = jdec($res);
    is($l->{total}, scalar @{ $l->{log} }, 'total matches');
    ok($l->{total} >= 2, 'the performed job has lifecycle rows');
    ok(exists $l->{log}[0]{$_}, "log rows carry $_")
        for qw(created level message);
    is($l->{log}[-1]{level}, 'error', 'the terminal failure is the tail');

    $res = hit_api(path => '/q/api/jobs/999999/log');
    is($res->[0], 404, 'missing job log is 404');
}

# ---- writes -----------------------------------------------------------------

{
    # retry the failed job
    my $res = hit_api(method => 'POST', path => "/q/api/jobs/$j2/retry");
    is($res->[0], 200, 'retry 200');
    is($q->job_info($j2)->{state}, 'inactive', 'and it requeued');

    # removing an active job is refused with directions
    my $act = $q->enqueue('t.ok', [], queue => 'act');
    $q->dequeue(queues => 'act');
    $res = hit_api(method => 'POST', path => "/q/api/jobs/$act/remove");
    is($res->[0], 409, 'active remove refused');
    like(jdec($res)->{error}, qr/retry it first/, 'with the way out');
}

# ---- bulk: selection-only, capped, per-id outcomes --------------------------

{
    my $res = hit_api(method => 'POST', path => '/q/api/jobs/bulk',
        body => '{"action":"retry","filter":{"state":"failed"}}');
    is($res->[0], 400, 'a filter payload is rejected outright');
    like(jdec($res)->{error}, qr/selection-only/, 'and told why');

    $res = hit_api(method => 'POST', path => '/q/api/jobs/bulk',
        body => '{"action":"eat","ids":[1]}');
    is($res->[0], 400, 'unknown action rejected');

    my $ids = File::Raw::JSON::file_json_encode([1 .. 501]);
    $res = hit_api(method => 'POST', path => '/q/api/jobs/bulk',
        body => qq({"action":"retry","ids":$ids}));
    is($res->[0], 400, 'the 500-id cap is enforced server-side');

    $res = hit_api(method => 'POST', path => '/q/api/jobs/bulk',
        body => qq({"action":"remove","ids":[$j3,999999]}));
    is($res->[0], 200, 'a valid bulk goes through');
    my $r = jdec($res);
    is($r->{succeeded}, 1, 'per-id outcomes: one removed');
    is($r->{failed}, 1, 'one skipped');
    is($r->{results}{999999}, 'skipped', 'named per id');
}

# ---- workers / locks / crons / stop -----------------------------------------

{
    my $res = hit_api(path => '/q/api/workers');
    is(jdec($res)->{total}, 1, 'workers listed');

    $res = hit_api(method => 'POST', path => "/q/api/workers/$wid/stop");
    is($res->[0], 200, 'stop accepted');
    is_deeply($q->backend->receive($wid), [['stop']],
              'and landed in the inbox');

    $q->lock('l1', 60);
    $res = hit_api(path => '/q/api/locks');
    is(jdec($res)->{total}, 1, 'locks listed');

    $res = hit_api(path => '/q/api/crons');
    is(jdec($res)->{total}, 0, 'no crons declared in this app');
    $res = hit_api(path => '/q/api/crons', query => 'search=x');
    is($res->[0], 200, 'crons search is accepted');
    is(jdec($res)->{total}, 0, 'and empty stays empty');

    $res = hit_api(method => 'POST', path => '/q/api/crons/x/enable');
    is($res->[0], 404, 'enabling an unknown cron is a 404');
}

# ---- stats and history shapes -----------------------------------------------

{
    my $res = hit_api(path => '/q/api/stats');
    my $s = jdec($res);
    ok(exists $s->{$_}, "stats has $_")
        for qw(inactive_jobs failed_jobs queues tasks active_workers
               enqueued_jobs schema_version);

    $res = hit_api(path => '/q/api/history');
    is(ref jdec($res)->{hourly}, 'ARRAY', 'history hourly series');
}

# ---- degradation: a broken endpoint leaves the page rendering ---------------

{
    # the page shell must not depend on any api call succeeding: it loads
    # scripts and containers only, and app.js shows EmptyState on errors.
    my $res = hit_api(path => '/q/jobs');
    is($res->[0], 200, 'the jobs page serves');
    my $html = $res->[2][0];
    unlike($html, qr{/api/}, 'the shell itself calls no API inline - '
                           . 'data loads from app.js, which handles errors');
    like($html, qr/spaContent/, 'and carries the SPA container');
}

done_testing();
