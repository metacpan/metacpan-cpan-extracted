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
    # The VERSION check is the load-bearing half. install_kw arrived in
    # Punk 0.04 and is how the queue/task/cron keywords reach an app
    # class; against an older Punk this file compiles far enough to call
    # it and then dies mid-BEGIN, which a smoker reports as a FAIL of
    # this dist rather than as the missing dependency it is. Punk is a
    # recommends, not a requires - the queue works standalone - so an
    # old one is a normal thing to meet.
    unless (eval { require Punk; Punk->VERSION('0.04'); 1 }) {
        require Test::More;
        Test::More::plan(skip_all => 'Punk 0.04 required for the plugin');
    }
}
plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

# The cron keyword's reconcile contract across deploys. One database,
# a fresh app package per "boot" - the closest one process gets to
# restarting an app four times with edited source.

my $file = queue_file();
my $DSN = "dbi:SQLite:dbname=$file";
my $inspect = Punk::Queue->new(dsn => $DSN);
$inspect->migrate;

# boot 1: the declaration lands in the store
{
    package RecApp::V1;
    use Punk;
    use Punk::Plugin::Queue;
    task 'report.nightly' => sub { 'ran' };
    cron '0 3 * * *' => 'report.nightly';
    plugin 'Queue' => { dsn => $DSN };
    RecApp::V1->to_app;
}
{
    my $c = $inspect->cron_info('report.nightly');
    ok($c, 'boot upserted the declared cron');
    is($c->{expr}, '0 3 * * *', 'with its expression');
    is($c->{task}, 'report.nightly', 'a bare task-name target IS the task');
    ok($c->{enabled}, 'enabled');
    ok($c->{next_run}, 'scheduled');
    is((gmtime $c->{next_run})[2], 3, 'for 03:00 UTC');
}

# boot 2: an edited expression recomputes the schedule
{
    package RecApp::V2;
    use Punk;
    use Punk::Plugin::Queue;
    task 'report.nightly' => sub { 'ran' };
    cron '0 4 * * *' => 'report.nightly';
    plugin 'Queue' => { dsn => $DSN };
    RecApp::V2->to_app;
}
is((gmtime $inspect->cron_info('report.nightly')->{next_run})[2], 4,
   'a redeploy with a new expression recomputes next_run');

# boot 3: removing the declaration disables, never deletes
{
    package RecApp::V3;
    use Punk;
    use Punk::Plugin::Queue;
    task 'health.probe' => sub { 'ok' };
    cron '*/15 * * * *' => 'health.probe';
    plugin 'Queue' => { dsn => $DSN };
    RecApp::V3->to_app;
}
{
    my $gone = $inspect->cron_info('report.nightly');
    ok($gone, 'the removed cron still exists - history survives');
    ok(!$gone->{enabled}, 'but it is disabled');
    ok($inspect->cron_info('health.probe')->{enabled},
       'and the new declaration is live');
    is($inspect->list_crons->{total}, 2, 'two rows, no deletions');
}

# boot 4: an operator's pause survives the redeploy
$inspect->enable_cron('health.probe', 0);
{
    package RecApp::V4;
    use Punk;
    use Punk::Plugin::Queue;
    task 'health.probe' => sub { 'ok' };
    cron '*/15 * * * *' => 'health.probe';
    plugin 'Queue' => { dsn => $DSN };
    RecApp::V4->to_app;
}
ok(!$inspect->cron_info('health.probe')->{enabled},
   'reconcile never resets an operator disable');

# re-enabling recomputes from now - the paused window is not a backlog
$inspect->dbh->do('UPDATE pq_crons SET next_run = 0 WHERE name = ?',
                  undef, 'health.probe');
$inspect->enable_cron('health.probe', 1);
{
    my $c = $inspect->cron_info('health.probe');
    ok($c->{enabled}, 're-enabled');
    ok($c->{next_run} > time - 60,
       're-enable schedules from now, not from the missed window');
    is($inspect->backend->_cron_tick, 0,
       'so nothing from the pause ever fires');
}

# a bad expression croaks the boot, by name
{
    my $ok = eval {
        package RecApp::V5;
        use Punk;
        use Punk::Plugin::Queue;
        task 't' => sub { 1 };
        cron '0 0 30 2 *' => 't';
        plugin 'Queue' => { dsn => $DSN };
        RecApp::V5->to_app;
        1;
    };
    ok(!$ok, 'an unmatchable cron croaks at boot');
    like($@, qr/can never fire/, 'naming the problem');
}

done_testing();
