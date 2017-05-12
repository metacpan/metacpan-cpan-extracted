use warnings;
use strict;

use Test::More tests => 1 + 2*(4 + 2*4 + 5)*8;

@B::ISA = qw(A);

sub A::flange { }

BEGIN {
	use_ok "Params::Classify", qw(
		is_blessed blessed_class is_strictly_blessed is_able
	);
}

my @class_names = qw(UNIVERSAL qwerty A B);
my @method_names = qw(qwerty can isa print flange);

sub test_blessed($$@) {
	my($scalar, $class, $isb, @expect) = @_;
	is(blessed_class($scalar), $class);
	is(&blessed_class($scalar), $class);
	is(!!is_blessed($scalar), !!$isb);
	is(!!&is_blessed($scalar), !!$isb);
	is(!!is_strictly_blessed($scalar), !!$isb);
	is(!!&is_strictly_blessed($scalar), !!$isb);
	is(!!is_able($scalar), !!$isb);
	is(!!&is_able($scalar), !!$isb);
	foreach my $cn (@class_names) {
		my $state = shift(@expect);
		is(!!is_blessed($scalar, $cn), !!$state);
		is(!!&is_blessed($scalar, $cn), !!$state);
		is(!!is_strictly_blessed($scalar, $cn), $state eq 2);
		is(!!&is_strictly_blessed($scalar, $cn), $state eq 2);
	}
	foreach my $mn (@method_names) {
		my $expect = !!shift(@expect);
		is(!!is_able($scalar, $mn), $expect);
		is(!!&is_able($scalar, $mn), $expect);
	}
}

test_blessed(undef,             undef,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
test_blessed("foo",             undef,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
test_blessed(123,               undef,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
test_blessed(*STDOUT,           undef,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
test_blessed({},                undef,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

test_blessed(bless({}, "main"), "main", 1, 1, 0, 0, 0, 0, 1, 1, 0, 0);
test_blessed(bless({}, "A"),    "A",    1, 1, 0, 2, 0, 0, 1, 1, 0, 1);
test_blessed(bless({}, "B"),    "B",    1, 1, 0, 1, 2, 0, 1, 1, 0, 1);

1;
