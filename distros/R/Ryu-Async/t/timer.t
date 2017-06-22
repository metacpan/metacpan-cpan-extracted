use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Refcount;

use Time::HiRes;

use IO::Async::Loop;
use Ryu::Async;
use Variable::Disposition qw(dispose);

my $loop = IO::Async::Loop->new;
$loop->add(
	my $ryu = Ryu::Async->new
);

{
	my $start = Time::HiRes::time;

	my $count = 0;
	my $timer = $ryu->timer(
		interval => 0.2
	);
	{
		Future->needs_any(
			$timer
			 ->take(10)
			 ->count
			 ->each(sub { $count = shift })
			 ->completed,
			$loop->timeout_future(after => 5)
		)->get;
		is($count, 10, 'have 10');
        my $elapsed = Time::HiRes::time - $start;
        note 'Elapsed ' . $elapsed . 's';
		cmp_deeply($elapsed, num(1.0, 0.15), 'elapsed time looks about right');
	}
	is_refcount($timer, 1, 'have only one ref after completion');
	dispose($timer);
}

is(
	0 + $ryu->children,
	0,
	'all child notifiers removed after timer finishes'
) or diag explain [ map ref, $ryu->children ];

done_testing;


