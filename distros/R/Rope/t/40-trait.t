use Test::More;

{
	package Initable;

	use Rope;
	use Rope::Autoload;

	property thing => (
		value => 500,
		enumerable => 1,
		initable => 1,
		handles_via => 'Rope::Handles::Array',
		handles => {
			get_thing => 'get',
      			set_thing => 'set',
      			push_thing => 'push',
			length_thing => 'length'
		}
	);

	property other => (
		value => 500,
		enumerable => 1,
		initable => 1,
		handles_via => 'Rope::Handles::Hash',
		handles => {
			get_other => 'get',
      			set_other => 'set',
      			assign_other => 'assign',
			length_other => 'length'
		}
	);

	1;
}

my $init = Initable->new(thing => [qw/one two three/], other => { one => 1, two => 2 });

is($init->{get_thing}(1), 'two');

is($init->{push_thing}('four'), 4);

is($init->{length_thing}(), 4);

is($init->get_thing(1), 'two');

is($init->push_thing('five'), 5);

is($init->length_thing(), 5);

is($init->get_other('one'), 1);

is($init->set_other('one', 5)->get('one'), 5);

my $hash = { one => 1, three => 3 };

is($init->assign_other($hash)->length, 3);

is($init->length_other, 3);

{
	package Initable::Monkey;

	use Rope;
	use Rope::Monkey;

	property thing => (
		value => 500,
		enumerable => 1,
		initable => 1,
		handles_via => 'Rope::Handles::Array',
		handles => {
			get_thing => 'get',
      			set_thing => 'set',
      			push_thing => 'push',
			length_thing => 'length'
		}
	);

	property other => (
		value => 500,
		enumerable => 1,
		initable => 1,
		handles_via => 'Rope::Handles::Hash',
		handles => {
			get_other => 'get',
      			set_other => 'set',
      			assign_other => 'assign',
			length_other => 'length'
		}
	);

	monkey;

	1;
}

my $init = Initable::Monkey->new(thing => [qw/one two three/], other => { one => 1, two => 2 });

is($init->{get_thing}(1), 'two');

is($init->{push_thing}('four'), 4);

is($init->{length_thing}(), 4);

is($init->get_thing(1), 'two');

is($init->push_thing('five'), 5);

is($init->length_thing(), 5);

is($init->get_other('one'), 1);

is($init->set_other('one', 5)->get('one'), 5);

my $hash = { one => 1, three => 3 };

is($init->assign_other($hash)->length, 3);

is($init->length_other, 3);


done_testing();
