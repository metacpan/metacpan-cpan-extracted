#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Time::HiRes ();
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

# rail 2: the task allowlist is a boot croak, never "all tasks"
{
    package NoListApp;
    use Punk;
    my $died = !eval {
        plugin 'Queue' => { dsn => $DSN, in_server => {} };
        1;
    };
    ::ok($died, 'in_server without a task allowlist croaks');
    ::like($@, qr/allowlist/, 'and says so');
}

# the lazy attach: to_app runs pre-fork with no loop, so the hook attaches
# on the first request of each process - and OFF a Hyperman worker there
# is no loop at all, so attach declines, warns once, and the app keeps
# serving. That degradation is this test's in-process reality.
{
    my $warned = '';
    local $SIG{__WARN__} = sub { $warned .= $_[0] };

    package InServerApp;
    use Punk;
    use Punk::Plugin::Queue;
    task('is.task' => sub { 'ran' });
    plugin 'Queue' => {
        dsn => $DSN,
        in_server => { tasks => ['is.task'], interval => 0.2, cap => 1 },
    };
    get '/ping' => sub { $_[0]->text('pong') };

    my $app = InServerApp->to_app;

    my $body = '';
    open my $in, '<', \$body or die $!;
    my $res = $app->({
        REQUEST_METHOD => 'GET', PATH_INFO => '/ping', QUERY_STRING => '',
        CONTENT_TYPE => '', CONTENT_LENGTH => 0, 'psgi.input' => $in,
    });
    ::is($res->[0], 200, 'the app serves normally');
    ::like($warned, qr/could not attach/,
           'and the attach declined loudly with no Hyperman loop');

    # a second request does not warn again - the branch is once-per-process
    $warned = '';
    open my $in2, '<', \$body or die $!;
    $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/ping',
             QUERY_STRING => '', CONTENT_TYPE => '', CONTENT_LENGTH => 0,
             'psgi.input' => $in2 });
    ::is($warned, '', 'the lazy attach is one predictable branch');
}

# The attach seam itself, driven directly on a real Hyperman loop: a
# worker child IS a process with a live cur_loop inside its tick, which is
# exactly the situation a web worker provides. Run the claim machinery
# through Punk::Queue::_inserver_attach on that loop via a task that
# performs the attach, then assert the allowlisted job ran and the
# non-allowlisted one did not.
SKIP: {
    skip 'Hyperman required for the live attach', 4
        unless eval { require Hyperman; 1 };

    my ($q) = make_queue();
    my $allowed = $q->enqueue('allowed.task');
    my $denied  = $q->enqueue('denied.task');

    $q->task('allowed.task' => sub { 'in-server ran me' });
    $q->task('denied.task'  => sub { 'must not run' });

    my $loop = Hyperman::Loop->new;
    my $attached = Punk::Queue::_inserver_attach($q, {
        tasks    => ['allowed.task'],
        interval => 0.05,
        cap      => 5,
    });

    # _inserver_attach needs a RUNNING loop (cur_loop); outside run it
    # declines - assert that first, then attach from inside the loop
    is($attached, 0, 'attach declines without a running loop');

    my $armed;
    $loop->timer(0.01, sub {
        $armed = Punk::Queue::_inserver_attach($q, {
            tasks    => ['allowed.task'],
            interval => 0.05,
            cap      => 5,
        });
    });
    # drive the loop long enough for the attach and a few claim ticks
    $loop->run_until($loop->timer_f(1.0));

    ok($armed, 'attach succeeds inside a running loop');
    is($q->job_info($allowed)->{state}, 'finished',
       'the allowlisted job ran in-server');
    is($q->job_info($denied)->{state}, 'inactive',
       'the non-allowlisted job was never claimed - rail 2 holds');
}

done_testing();
