use Smart::Dispatch -all =>,
	class => { table => 'Local::CustomDispatch::Table', match => 'Local::CustomDispatch::Match' };
use Test::More tests => 4;
use Test::Warn;
use Carp;

{
	package Local::CustomDispatch::Table;
	use Moo;
	extends 'Smart::Dispatch::Table';
}

{
	package Local::CustomDispatch::Match;
	use Moo;
	extends 'Smart::Dispatch::Match';
}

my $dispatch = dispatcher {
	match [1..10],
		dispatch { "Single digit $_" };
	match 1_000,
		dispatch { "1e3" };
	match_using { $_ < 0 }
		failover { "F" }
};

my $match = $dispatch->match_list->[0];

isa_ok $dispatch, 'Smart::Dispatch::Table', '$dispatch';
isa_ok $dispatch, 'Local::CustomDispatch::Table', '$dispatch';
isa_ok $match, 'Smart::Dispatch::Match', '$match';
isa_ok $match, 'Local::CustomDispatch::Match', '$match';
