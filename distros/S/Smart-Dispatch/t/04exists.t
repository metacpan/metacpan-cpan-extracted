use Smart::Dispatch;
use Test::More tests => 17;
use Test::Warn;
use Carp;

no warnings;

sub action_1_to_999 {
	"1 to 999";
}

my $dispatch = dispatcher {
	match [1..10],
		dispatch { "Single digit $_" };
	match 1_000,
		dispatch { "1e3" };
	match qr/^\d{4}/,
		dispatch { "Over a thousand\n"};
	match_using { $_ > 0 and $_ < 1000 }
		dispatch \&action_1_to_999;
	match_using { $_ < 0 }
		failover { "F" }
};

ok $dispatch->exists(1);
ok !$dispatch->exists(0);

ok ($dispatch~~1);
ok !($dispatch~~0);

ok !($dispatch~~-1);
is $dispatch->(-1), 'F';

ok !($dispatch~~'Hello');
ok !defined $dispatch->('Hello');

my $match = ($dispatch ~~ 1_000);
isa_ok $match, 'Smart::Dispatch::Match', '$match';
ok $match->value_matches(1_000);
ok !$match->value_matches(999);
is $match->conduct_dispatch(1_000), '1e3';
is $match->conduct_dispatch(999), '1e3';

ok ($match ~~ 1_000);
ok !($match ~~  999);
is $match->(1_000), '1e3';
is $match->(999), '1e3';
