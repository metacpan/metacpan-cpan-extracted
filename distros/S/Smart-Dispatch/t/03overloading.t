use Smart::Dispatch;
use Test::More tests => 5;
use Test::Warn;
use Carp;

sub action_1_to_999 {
	"1 to 999";
}

my $dispatch = dispatcher {
	match 0,
		value => "Zero";
	match [1..10],
		dispatch { "Single digit $_" };
	match 1_000,
		dispatch { "1e3" };
	match qr/^\d{4}/,
		dispatch { "Over a thousand\n"};
	match_using { $_ > 0 and $_ < 1000 }
		dispatch \&action_1_to_999;
	otherwise
		failover { Carp::carp "failover"; "F" }
};

is $dispatch->(0),  'Zero';
is $dispatch->(3),  'Single digit 3';
is $dispatch->(23), '1 to 999';

my $r;
warnings_like { $r = $dispatch->(-1) } qr{failover}, 'failovers get run';
is $r, 'F';

