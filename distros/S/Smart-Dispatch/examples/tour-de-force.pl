use 5.010;
use strict;
use Smart::Dispatch;

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

$dispatch += dispatcher { match 3, value => 'Trinity' };

say $dispatch->(0);   # call dispatch table on value '0'
say $dispatch->(1);   # call dispatch table on value '1'
say $dispatch->(3);   # call dispatch table on value '3'
say $dispatch->(23);  # guess!

# call dispatch table on '999999' but only if the dispatch table
# has an entry that covers value '-1'.
say $dispatch->(999999) if $dispatch ~~ -1;

# call dispatch table on '1000' but only if the dispatch table
# has an entry that covers value '4'.
say $dispatch->(1000) if $dispatch ~~ 4;

say (($dispatch ~~ -1) ? '$dispatch can handle "-1"' : '$dispatch cannot handle "-1"');
$dispatch .= dispatcher { match_using {$_ < 0} value => 'Less than zero' };
say (($dispatch ~~ -1) ? '$dispatch can handle "-1"' : '$dispatch cannot handle "-1"');

say $dispatch->(-1);

