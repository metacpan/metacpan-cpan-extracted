use Smart::Dispatch;
use Test::More tests => 12;
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

my @x;
is scalar(@x = $dispatch->all_matches), 6, 'all_matches';
is scalar(@x = $dispatch->conditional_matches), 5, 'conditional_matches';
is scalar(@x = $dispatch->unconditional_matches), 1, 'unconditional_matches';

is $dispatch->action(0),  'Zero';
is $dispatch->action(3),  'Single digit 3';
is $dispatch->action(23), '1 to 999';

ok !$dispatch->match_list->[0]->is_failover;
ok !$dispatch->match_list->[0]->is_unconditional;

ok $dispatch->match_list->[-1]->is_failover;
ok $dispatch->match_list->[-1]->is_unconditional;

my $r;
warnings_like { $r = $dispatch->action(-1) } qr{failover}, 'failovers get run';
is $r, 'F';

