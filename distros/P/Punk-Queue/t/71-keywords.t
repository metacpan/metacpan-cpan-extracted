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

my $file = queue_file();
my $DSN = "dbi:SQLite:dbname=$file";

# The double entry point, order 1: use first (compile-ordered), plugin
# after. Declarations recorded before registration apply at register.
{
    package KwApp::Controller::Reports;
    sub nightly { 'ran the report' }
}
{
    package KwApp;
    use Punk;
    use Punk::Plugin::Queue;

    queue 'mail' => { attempts => 5, priority => 2 };
    task 'mail.send' => sub { my ($job, $to) = @_; "sent:$to" };
    cron '0 3 * * *' => 'Reports#nightly', { queue => 'mail' };

    plugin 'Queue' => { dsn => $DSN };
}
{
    my $st = Punk::Plugin::Queue->state_for('KwApp');
    ok($st->{registered}, 'registered');
    is_deeply($st->{queues}{mail}, { attempts => 5, priority => 2 },
              'queue declaration recorded');
    is(scalar @{ $st->{tasks} }, 1, 'task recorded');
    is($st->{crons}[0]{name}, 'Reports-nightly',
       'cron name defaults to the sanitised target string - stable across restarts');
    is($st->{crons}[0]{queue}, 'mail', 'cron options recorded');
}

# compile: to_app resolves targets; queue defaults apply on enqueue
{
    package KwApp;
    KwApp->to_app;
    my $q = queue();
    my $id = $q->enqueue('mail.send', [], queue => 'mail');
    ::is($q->job_info($id)->{attempts}, 5,
         'the queue keyword drove enqueue defaults');
    ::ok($q->task('mail.send'), 'the task landed in the registry');
}

# a Controller#method task typo croaks at to_app, not at first dispatch
{
    package TypoApp;
    use Punk;
    use Punk::Plugin::Queue;
    task 'x' => 'No::Such#method';
    plugin 'Queue' => { dsn => $DSN };
    my $died = !eval { TypoApp->to_app; 1 };
    ::ok($died, 'a target typo croaks at to_app');
    ::like($@, qr/No::Such/, 'naming the class');
}

# order 2: plugin first, keywords after. The trap is real and this test
# documents its exact boundary: `plugin` runs at RUNTIME, so the bare
# keyword syntax (`task 'x' => ...`) on a later line still fails at
# compile - only the parenthesised call form works plugin-first, because
# Perl compiles `task(...)` as a call resolved at runtime. The SYNOPSIS
# form (`use Punk::Plugin::Queue` first) is the one that makes barewords
# work.
{
    package TerseApp;
    use Punk;
    plugin 'Queue' => { dsn => $DSN };
    task('later.task' => sub { 1 });     # parens: resolved at runtime
    TerseApp->to_app;
    ::ok(queue()->task('later.task'),
         'plugin-first works with parenthesised keyword calls');
}

# use alone installs keywords but does NOT register: cron with no later
# plugin line croaks at to_app with the precise message
{
    package Orphan;
    use Punk;
    use Punk::Plugin::Queue;
    cron '@daily' => 'Nobody#home';
    my $died = !eval { Orphan->to_app; 1 };
    ::ok($died, 'keywords without registration croak at to_app');
    ::like($@, qr/cron used but plugin 'Queue' was never registered/,
           'with the exact message');
}
{
    my $st = Punk::Plugin::Queue->state_for('Orphan');
    ok(!$st->{registered}, 'use alone did not register the plugin');
    ok(!$st->{queue},      'and built no queue');
}

# a cron naming a registered task string needs no resolution
{
    my $f2 = PQTest::queue_file();
    package CronTaskApp;
    use Punk;
    use Punk::Plugin::Queue;
    task 'nightly' => sub { 1 };
    cron '@daily' => 'nightly';
    plugin 'Queue' => { dsn => "dbi:SQLite:dbname=$f2" };
    CronTaskApp->to_app;
    my $st = Punk::Plugin::Queue->state_for('CronTaskApp');
    ::is($st->{crons}[0]{task}, 'nightly', 'cron bound to the named task');
}

done_testing();
