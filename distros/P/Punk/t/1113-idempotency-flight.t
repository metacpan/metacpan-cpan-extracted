#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use Time::HiRes ();
use POSIX ();
use File::Raw::JSON qw(file_json_encode file_json_decode);
use Punk ();

# The single-flight lock, driven from TWO PROCESSES - the arrangement a
# dropped connection actually produces, and the one no in-process test can
# fake. The interleavings are scripted through flag files, not sleeps: the
# first holder blocks inside its handler until this parent releases it, so
# the second request demonstrably arrives WHILE the lock is held.
#
# Two interleavings, one per documented outcome:
#   - the retry waits, the holder finishes, the retry REPLAYS: one
#     execution, two identical answers.
#   - the retry waits out the lock budget and EXECUTES ANYWAY: a stalled
#     request is worse than a duplicated one, and that rule holds across
#     processes too.
#
# Fork discipline: the children never touch the TAP pipe - stdio to
# /dev/null, POSIX::_exit - or the harness sees a duplicate plan.

my $dir = File::Temp->newdir;

{
    package Flight;
    use Punk;
    cache 'file', dir => "$dir/patient", lock_wait => 30;
    plugin 'Idempotency' => { scope => sub { 'alice' } };

    post '/slow' => sub {
        my ($c) = @_;
        open my $r, '>>', "$dir/ran" or die $!; print {$r} "$$\n"; close $r;
        open my $f, '>', "$dir/executing" or die $!; close $f;
        my $t = Time::HiRes::time() + 15;
        Time::HiRes::sleep(0.01)
            while Time::HiRes::time() < $t && !-e "$dir/release";
        $c->json({ pid => $$ }, 201);
    }, { idempotent => 1 };
}
{
    package Impatient;
    use Punk;
    cache 'file', dir => "$dir/impatient", lock_wait => 0.3;
    plugin 'Idempotency' => { scope => sub { 'alice' }, lock_wait => 0.3 };

    post '/slow' => sub {
        my ($c) = @_;
        open my $r, '>>', "$dir/ran2" or die $!; print {$r} "$$\n"; close $r;
        open my $f, '>', "$dir/executing2" or die $!; close $f;
        my $t = Time::HiRes::time() + 15;
        Time::HiRes::sleep(0.01)
            while Time::HiRes::time() < $t && !-e "$dir/release2";
        $c->json({ pid => $$ }, 201);
    }, { idempotent => 1 };
}

{
    # A store tuned the way a cache is - a lock is abandoned after 0.3s -
    # behind a handler that takes far longer than that. The plugin's own
    # budget is what decides here, and it is left at its default.
    package Payment;
    use Punk;
    cache 'file', dir => "$dir/payment", lock_wait => 0.3;
    plugin 'Idempotency' => { scope => sub { 'alice' } };

    post '/slow' => sub {
        my ($c) = @_;
        open my $r, '>>', "$dir/ran3" or die $!; print {$r} "$$\n"; close $r;
        open my $f, '>', "$dir/executing3" or die $!; close $f;
        my $t = Time::HiRes::time() + 15;
        Time::HiRes::sleep(0.01)
            while Time::HiRes::time() < $t && !-e "$dir/release3";
        $c->json({ pid => $$ }, 201);
    }, { idempotent => 1 };
}

# compiled BEFORE any fork, so every process runs the same frozen app
my %app = (patient => Flight->to_app, impatient => Impatient->to_app,
           payment => Payment->to_app);

# Run one request in a forked process; the result lands in $dir/$label.json
# (written to a temp name and renamed, so the parent never reads half a file).
sub spawn {
    my ($label, $which, $key) = @_;
    my $pid = fork // die "fork: $!";
    return $pid if $pid;
    open STDIN,  '<', '/dev/null';
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', '/dev/null';
    my $out = eval {
        my $body = '{}';
        open my $in, '<', \$body or die $!;
        my $r = $app{$which}->({
            REQUEST_METHOD => 'POST',
            PATH_INFO      => '/slow',
            QUERY_STRING   => '',
            CONTENT_TYPE   => 'application/json',
            CONTENT_LENGTH => length $body,
            'psgi.input'   => $in,
            HTTP_IDEMPOTENCY_KEY => $key,
        });
        { status  => $r->[0],
          headers => { @{ $r->[1] } },
          body    => join('', @{ $r->[2] }) };
    } || { status => 0, headers => {}, body => "died: $@" };
    open my $fh, '>', "$dir/$label.tmp" or POSIX::_exit(1);
    print {$fh} file_json_encode($out);
    close $fh;
    rename "$dir/$label.tmp", "$dir/$label.json";
    POSIX::_exit(0);
}

sub wait_for {
    my ($cond, $what) = @_;
    my $t = Time::HiRes::time() + 15;
    while (Time::HiRes::time() < $t) {
        return 1 if $cond->();
        Time::HiRes::sleep(0.01);
    }
    fail("timed out waiting for $what");
    return 0;
}

sub result {
    my ($label) = @_;
    wait_for(sub { -e "$dir/$label.json" }, "$label result") or return;
    open my $fh, '<', "$dir/$label.json" or die $!;
    local $/;
    return file_json_decode(<$fh>);
}

sub ran_lines {
    my ($file) = @_;
    open my $fh, '<', "$dir/$file" or return ();
    return map { chomp; $_ } <$fh>;
}

# ---- the retry waits and replays ---------------------------------------------

{
    my $a = spawn('a', patient => 'shared-key');
    wait_for(sub { -e "$dir/executing" }, 'the first holder to be mid-handler');

    # B arrives while A demonstrably holds the lock. A brief courtesy pause
    # gives B time to reach the wait; nothing is asserted about it - if B is
    # slower than this, it finds the recorded entry instead, and every
    # assertion below still holds.
    my $b = spawn('b', patient => 'shared-key');
    Time::HiRes::sleep(0.3);
    open my $rel, '>', "$dir/release" or die $!; close $rel;

    waitpid $a, 0;
    waitpid $b, 0;

    my $ra = result('a');
    my $rb = result('b');
    my @ran = ran_lines('ran');

    is(scalar @ran, 1, 'the handler ran in ONE process - the whole claim');
    is($ra->{status}, 201, 'the holder got its own execution');
    ok(!defined $ra->{headers}{'Idempotency-Replayed'},
        '...not marked as a replay');
    is($rb->{status}, 201, 'the concurrent retry got an answer');
    is($rb->{headers}{'Idempotency-Replayed'}, 'true',
        '...the replay, from another process entirely');
    is($rb->{body}, $ra->{body},
        'byte-identical to what the first caller was sent');
    # Compared as a VALUE, not as JSON text. The handler writes "$$" to
    # the ran file before it encodes $$, and how much of that scalar's
    # numeric identity survives being used as a string is perl's own
    # business: 5.16 hands the encoder a string and spells it "12345",
    # later perls keep IOK and spell it 12345. The body above is already
    # asserted byte-identical to B's, so one side proves both.
    is(file_json_decode($ra->{body})->{pid} + 0, $ran[0] + 0,
        'and both carry the pid of the one process that did the work');
}

# ---- the retry waits out the budget and executes -----------------------------

{
    my $a = spawn('a2', impatient => 'shared-key');
    wait_for(sub { -e "$dir/executing2" }, 'the slow holder to be mid-handler');

    my $b = spawn('b2', impatient => 'shared-key');

    # The proof is in the ORDER: ran2 reaches two lines while release2 does
    # not exist yet, so the second execution happened while the first holder
    # was still inside its handler - the budget genuinely gave up, it did
    # not just run after.
    wait_for(sub { ran_lines('ran2') >= 2 },
             'the retry to give up waiting and execute');
    ok(!-e "$dir/release2", 'while the first holder still held the lock');

    open my $rel, '>', "$dir/release2" or die $!; close $rel;
    waitpid $a, 0;
    waitpid $b, 0;

    my $rb = result('b2');
    my @ran = ran_lines('ran2');
    is(scalar @ran, 2, 'both processes executed');
    isnt($ran[0], $ran[1], '...and they were different processes');
    is($rb->{status}, 201, 'the impatient retry answered from its own run');
    ok(!defined $rb->{headers}{'Idempotency-Replayed'},
        'and is not a replay - duplicated work, not a stalled request');
}

# ---- a handler slower than the store's lock_wait keeps its lock --------------
# The retry this plugin exists for: the client gave up on a slow request and
# sent it again. By then the lock is older than the cache store's lock_wait,
# which is when a cache compute's lock is taken for abandoned - and the retry
# used to take it, and run beside the first.
{
    my $a = spawn('a3', payment => 'shared-key');
    wait_for(sub { -e "$dir/executing3" }, 'the payment to be mid-handler');

    Time::HiRes::sleep(2.2);          # well past 0.3s, and any mtime slack
    my $b = spawn('b3', payment => 'shared-key');
    Time::HiRes::sleep(1.0);          # long enough to have stolen and run

    is(scalar(ran_lines('ran3')), 1,
        'a retry arriving after the store\'s lock_wait does not run beside it');
    ok(!-e "$dir/b3.json", '...it is waiting');

    open my $rel, '>', "$dir/release3" or die $!; close $rel;
    waitpid $a, 0;
    waitpid $b, 0;

    my $rb = result('b3');
    is(scalar(ran_lines('ran3')), 1, 'the handler ran once in all');
    is($rb->{status}, 201, 'the retry got an answer');
    is($rb->{headers}{'Idempotency-Replayed'}, 'true', '...the replay');
}

done_testing;
