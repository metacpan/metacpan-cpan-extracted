use v5.10;
use strict;
use warnings;

use Test::More;

BEGIN {
	unless (eval { require Moo } && Moo->VERSION > 2) {
		plan skip_all => 'These tests require Moo';
	}
}

{

	package TestMooParent;

	use Moo;
	use Mooish::AttributeBuilder;

	has param 'mandatory';

	has param 'optional1' => (
		default => undef,
	);

	has option 'optional2';

	has field 'lazy_built' => (
		lazy => sub {
			return shift->mandatory;
		},
		clearer => 1,
		predicate => 1,
	);

	has field 'rw_trigger' => (
		writer => 1,
	);
}

{

	package TestMoo;

	use Moo;
	use Mooish::AttributeBuilder;

	extends 'TestMooParent';

	has extended 'rw_trigger' => (
		trigger => 1,
	);

	sub _trigger_rw_trigger
	{
		my ($self) = @_;

		$self->clear_lazy_built;
	}
}

subtest 'testing parameters (passing all)' => sub {
	my $obj = TestMoo->new(
		mandatory => 'mandatory',
		optional1 => 'optional1',
		optional2 => 'optional2',
	);

	is $obj->mandatory, 'mandatory', 'mandatory ok';
	is $obj->optional1, 'optional1', 'optional1 ok';
	is $obj->optional2, 'optional2', 'optional2 ok';
	ok $obj->has_optional2, 'optional2 predicate ok';
};

subtest 'testing parameters (passing mandatory)' => sub {
	my $obj = TestMoo->new(
		mandatory => 'mandatory',
	);

	ok !defined $obj->optional1, 'optional1 ok';
	ok !$obj->has_optional2, 'optional2 ok';
};

subtest 'testing fields' => sub {
	my $obj = TestMoo->new(
		mandatory => 'mandatory',
	);

	ok !$obj->has_lazy_built, 'predicate ok (before)';
	is $obj->lazy_built, 'mandatory', 'lazy value ok';
	ok $obj->has_lazy_built, 'predicate ok (after)';

	$obj->set_rw_trigger('some value');
	ok !$obj->has_lazy_built, 'predicate ok (after trigger)';
};

done_testing;

