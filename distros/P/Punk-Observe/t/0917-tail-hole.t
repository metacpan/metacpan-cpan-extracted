#!perl
use 5.010;
use strict;
use warnings;
use Config;
use POSIX ();
use Time::HiRes ();
use Test::More;
use Punk::Observe;

# A PUBLISHER KILLED INSIDE ITS COMMIT leaves a hole in the ring. The tail's
# drain must come back PROMPTLY - the ring never sleeps at a hole - deliver
# what came before it, and on a later drain, once the ring has proven the
# publisher dead, step over the filled hole and count it as exactly one gap.
# A stream that is short says so.
#
# The stall hook that widens the window is Shared::Arena's, on the region
# header, so the ring is opened on an arena the test made and can reach.

my $L = 'Punk::Observe::Live';
plan skip_all => 'no fork on this platform' unless $Config{d_fork};
plan skip_all => 'no Shared::Arena ring in this build' unless $L->can('have_bus')->();
plan skip_all => 'Shared::Arena not loadable' unless eval { require Shared::Arena; 1 };

my $arena = Shared::Arena->create(size => 512 * 1024);
$arena->region('flag', size => 16);
$arena->poke('flag', 0, '....');

ok($L->can('bus_init')->(32, $arena), 'the tail ring opened on the test\'s arena');
$L->can('bus_reset_cursors')->();
my $topic = $L->can('topic')->('acme');

$L->can('bus_publish')->($topic, 'before');

# Half a second inside the commit, and a ring told to ask after a tenth.
$arena->_test_timing(stall_us => 500_000, reap_grace_us => 100_000);

my $pid = fork();
die "fork: $!" unless defined $pid;
if (!$pid) {
    $arena->poke('flag', 0, 'GO!!');
    $L->can('bus_publish')->($topic, 'doomed');     # stalls inside publish
    POSIX::_exit(0);
}
my $spins = 0;
while ($arena->peek('flag', 0, 4) ne 'GO!!') {
    die "child never started\n" if ++$spins > 50_000_000;
}
Time::HiRes::sleep(0.05);                           # inside the stall now
kill 'KILL', $pid;
waitpid $pid, 0;
isnt($? & 127, 0, 'the publisher was killed mid-record');
$arena->_test_timing(stall_us => 0);

$L->can('bus_publish')->($topic, 'after');

# The drain that meets the hole: prompt, and everything before it delivered.
my $t0 = Time::HiRes::time();
my $d  = $L->can('bus_drain')->($topic);
my $took = (Time::HiRes::time() - $t0) * 1000;
cmp_ok($took, '<', 50, sprintf('the drain at the hole came back at once (%.1fms)', $took));
is_deeply($d->{rows}, ['before'], 'and delivered what came before it');
is(0 + $d->{gaps}, 0, 'with no gap counted before the publisher is proven dead');

# Later drains: the grace period runs on the cursor, the ring asks whether the
# publisher is dead, fills the hole, and the tail steps over it.
my ($gaps, @rows);
for (1 .. 60) {
    my $more = $L->can('bus_drain')->($topic);
    push @rows, @{ $more->{rows} };
    $gaps = 0 + $more->{gaps};
    last if grep { $_ eq 'after' } @rows;
    Time::HiRes::sleep(0.05);
}
is_deeply(\@rows, ['after'], 'the record behind the hole arrived');
is($gaps, 1, 'and the dead publisher\'s record is counted as exactly one gap');

done_testing;
