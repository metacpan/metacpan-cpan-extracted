#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use File::Temp ();
use Time::HiRes ();

# The application's own use of the bus: $app->subscribe / $c->publish.
#
# Three things that can only be shown with a real pool:
#
#   - FANOUT reaches every worker;
#   - a QUEUE GROUP is handled by exactly one worker per message, and the
#     work spreads;
#   - with no Hyperman at all, none of it croaks and a room stays local -
#     the behaviour that existed before any of this.

BEGIN {
    eval { require Hyperman; 1 }
        or plan skip_all => 'Hyperman required for these tests';
}
plan skip_all => 'this Hyperman has no message bus (needs hm_abi v5)'
    unless Hyperman->can('bus_init');
plan skip_all => 'fork is POSIX-only here' if $^O eq 'MSWin32';

my $dir  = File::Temp::tempdir(CLEANUP => 1);
my $fan  = "$dir/fan.log";
my $grp  = "$dir/group.log";
my $N    = 40;

my $port = 26300 + ($$ % 200);
my $host = "127.0.0.1:$port";

my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';

    package BusApp;
    use Punk;

    get '/say/:msg' => sub {
        my ($c) = @_;
        $c->publish('chat' => $c->param('msg'));
        $c->publish('work' => $c->param('msg'));
        $c->text('ok');
    };
    get '/whoami' => sub { $_[0]->text("$$") };

    # What this worker has LOST - messages the ring overwrote before it read
    # them. Without it a short count is ambiguous: a worker that dropped
    # messages and a worker that simply has not drained yet look identical,
    # and only one of those is a bug.
    get '/gaps' => sub { $_[0]->text("$$ " . Hyperman->bus_gaps) };

    package main;

    # Both registered AT BOOT, in the parent, before the fork - the only
    # moment a subscription reaches every worker.
    my $app = BusApp->punk_app;

    # fanout: every worker records every message
    $app->subscribe('chat' => sub {
        open my $fh, '>>', $fan or return;
        print $fh "$$ $_[1]\n";
        close $fh;
    });

    # a queue group: exactly one worker records each message
    $app->subscribe('work' => sub {
        open my $fh, '>>', $grp or return;
        print $fh "$$ $_[1]\n";
        close $fh;
    }, group => 'workers');

    Hyperman->run(app => BusApp->to_app, host => '127.0.0.1',
                  port => $port, workers => 3);
    exit 0;
}

for (1 .. 80) {
    my $s = IO::Socket::INET->new(PeerAddr => $host);
    last if $s;
    Time::HiRes::sleep(0.1);
}

sub get_path {
    my ($path) = @_;
    my $s = IO::Socket::INET->new(PeerAddr => $host) or return '';
    $s->autoflush(1);
    syswrite $s, "GET $path HTTP/1.1\r\nHost: $host\r\nConnection: close\r\n\r\n";
    my $body = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        while (sysread $s, my $c, 4096) { $body .= $c }
        alarm 0;
    };
    alarm 0;
    close $s;
    return $body;
}

sub lines_of {
    my ($f) = @_;
    open my $fh, '<', $f or return ();
    my @l = <$fh>;
    close $fh;
    chomp @l;
    return @l;
}

# ---- how many workers answer ------------------------------------------------
my %serving;
for (1 .. 20) {
    my $body = get_path('/whoami');
    $serving{$1}++ if $body =~ /(\d+)\s*\z/;
}

# ---- publish N messages -----------------------------------------------------
get_path("/say/msg$_") for 1 .. $N;

# Wait for delivery to CONVERGE, within a bound - not for a fixed second.
#
# Delivery is prompt, but promptness is not what the bus promises, and a
# smoker running a DEBUGGING perl alongside a dozen other builds can leave a
# worker unscheduled for longer than any sleep somebody picks. A fixed window
# followed by an immediate kill turns that into a FAIL that says "the bus lost
# messages" when the truth is "this box was busy" - which is exactly the
# report that came back from CPAN Testers against 0.21.
#
# The bound is generous because it costs nothing when things are working: the
# loop leaves as soon as the counts are right, so the usual run is one pass.
my (@fanout, @group);
for my $attempt (1 .. 200) {          # up to ~20s
    Time::HiRes::sleep(0.1);
    @fanout = lines_of($fan);
    @group  = lines_of($grp);

    my %by;
    $by{ (split ' ', $_)[0] }++ for @fanout;
    last if @group >= $N && keys %by && !grep { $_ != $N } values %by;
}

# Every worker's gap counter, collected while the server is still up. A gap is
# the ring genuinely dropping a message under pressure - the one thing that
# makes a short count a real fault rather than a slow worker.
my %gaps;
for (1 .. 30) {
    my $b = get_path('/gaps');
    $gaps{$1} = $2 if $b =~ /(\d+)\s+(\d+)\s*\z/;
}

# The probe itself, asserted rather than assumed. A diagnostic that is only
# exercised on the run where it is needed is a diagnostic that turns out to be
# broken on the run where it is needed - and this one exists to answer a
# question a CPAN Testers report could not.
cmp_ok(scalar keys %gaps, '>=', 1,
    'the gap counter answers, so a short count below can say whether the '
  . 'ring dropped anything');

kill 'TERM', $pid;
waitpid $pid, 0;

my $workers = keys %serving;
note "workers answering: $workers";

# ---- FANOUT ------------------------------------------------------------------
{
    my %by_worker;
    $by_worker{ (split ' ', $_)[0] }++ for @fanout;

    cmp_ok(scalar keys %by_worker, '>=', 1, 'the fanout subscription ran');

    SKIP: {
        skip 'only one worker took the requests, so fanout across workers '
           . 'cannot be distinguished from a local callback here', 1
            if keys %by_worker < 2;

        my @short = grep { $by_worker{$_} != $N } keys %by_worker;
        is_deeply(\@short, [],
            'FANOUT: every worker that subscribed saw every message')
            or diag sprintf
                "%s\ngaps: %s\n%s",
                join(', ', map { "$_ saw $by_worker{$_} of $N" }
                           sort keys %by_worker),
                (%gaps ? join(', ', map { "$_=$gaps{$_}" } sort keys %gaps)
                       : 'not collected'),
                (grep { $gaps{$_} } @short)
                    ? 'the ring DROPPED messages for a short worker, which is '
                    . 'a real loss - it fell far enough behind to be lapped'
                    : 'no gaps were counted, so nothing was dropped: those '
                    . 'messages are still unread on the ring, and this worker '
                    . 'never got scheduled to drain them within the wait';
    }
}

# ---- QUEUE GROUP -------------------------------------------------------------
{
    my (%count, %by_worker);
    for (@group) {
        my ($w, $m) = split ' ';
        $count{$m}++;
        $by_worker{$w}++;
    }

    is(scalar @group, $N,
        'QUEUE GROUP: the pool handled every message, and only once each')
        or diag sprintf 'handled %d of %d', scalar @group, $N;

    is_deeply([ sort grep { $count{$_} != 1 } keys %count ], [],
        'no message was handled twice - which is the whole point of a group '
      . 'rather than a fanout');

    is_deeply([ grep { !$count{"msg$_"} } 1 .. $N ], [], 'and none was missed');

    note 'per worker: '
       . join(', ', map { "$_=$by_worker{$_}" } sort keys %by_worker);
    # One worker claiming everything is a legitimate outcome - it was free,
    # and that IS the balancing rule - so this file does not assert a spread.
    # That the claim spreads under uneven load is asserted where it can be
    # controlled, in Hyperman's own t/35-bus.t.
}

# ---- with no Hyperman ABI at all ---------------------------------------------
# The degradation path. A Punk under a server that is not Hyperman keeps the
# behaviour it always had: a room is local, publish says so, and nothing
# croaks. PUNK_NO_HM_ABI forces that in a fresh process, because the ABI
# resolve is cached after its first attempt.
{
    my $out = `PUNK_NO_HM_ABI=1 $^X -Mblib -e '
        require Punk;
        require Punk::WebSocket::Room;
        my \$room = Punk::WebSocket::Room->named("solo");
        my \$n = eval { \$room->broadcast("hello"); 1 } ? "lived" : "died";
        my \$p = eval { Punk::App->publish("t","x") };
        print "broadcast=\$n publish=", (defined \$p ? \$p : "undef"), "\n";
    ' 2>&1`;

    like($out, qr/broadcast=lived/,
        'with no Hyperman ABI a room broadcast still works and does not croak');
    like($out, qr/publish=0/,
        'and publish reports 0 - local only - rather than pretending it '
      . 'reached a pool that is not there');
}

done_testing;
