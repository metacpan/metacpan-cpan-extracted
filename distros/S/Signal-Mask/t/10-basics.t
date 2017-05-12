#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More tests => 16;
use Signal::Mask;
use Signal::Pending;
use POSIX qw/SIGUSR1 SIGUSR2/;

my $counter1 = 0;
my $counter2 = 0;

my $base_masked = %Signal::Mask;

diag("$base_masked signals masked before tests were run") if $base_masked;

$SIG{USR1} = sub { $counter1++ };
$SIG{USR2} = sub { $counter2++ };

is $counter1, 0, 'Counter1 starts at zero';
is $counter2, 0, 'Counter2 starts at zero';

ok kill(SIGUSR1, $$), 'Sent usr1 signal';

is %Signal::Pending, 0, 'No pending signals';

is $counter1, 1, 'Counter1 is 1 now';
is $counter2, 0, 'Counter2 is still 0';

{
	local $Signal::Mask{USR1} = 1;

	is %Signal::Mask, 1 + $base_masked, 'One signal masked';

	ok kill(SIGUSR1, $$), 'Sent usr1 signal';
	ok kill(SIGUSR2, $$), 'Sent usr2 signal';

	is %Signal::Pending, 1, 'One pending signal';
	ok $Signal::Pending{USR1}, 'SIGUSR1 pending';

	is $counter1, 1, 'Counter1 is still 1';
	is $counter2, 1, 'Counter2 is now 1';
}

is %Signal::Pending, 0, 'No pending signals';

is $counter1, 2, 'Counter1 is 2 now';
is $counter2, 1, 'Counter2 is still 1';
