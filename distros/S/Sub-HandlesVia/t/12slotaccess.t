use strict;
use warnings;
use Test::More;
{ package Local::Dummy1; use Test::Requires 'Moo' };
{ package Local::Dummy1; use Test::Requires 'Moose' };
{ package Local::Dummy1; use Test::Requires 'MooseX::ArrayRef' };
{ package Local::Dummy1; use Test::Requires 'MooseX::InsideOut' };
{ package Local::Dummy1; use Test::Requires 'Mouse' };

{
	package Local::Class1;
	use Moo;
	use Sub::HandlesVia;
	has foo => (
		is           => 'ro',
		lazy         => 1,
		default      => sub { 665 },
		handles_via  => 'Scalar',
		handles      => {
			ref_to_foo => 'scalar_reference',
		},
	);
}

{
	package Local::Class2;
	use Moose;
	use Sub::HandlesVia;
	has foo => (
		is           => 'ro',
		lazy         => 1,
		default      => sub { 665 },
		handles_via  => 'Scalar',
		handles      => {
			ref_to_foo => 'scalar_reference',
		},
	);
}

{
	package Local::Class3;
	use Mouse;
	use Sub::HandlesVia;
	has foo => (
		is           => 'ro',
		lazy         => 1,
		default      => sub { 665 },
		handles_via  => 'Scalar',
		handles      => {
			ref_to_foo => 'scalar_reference',
		},
	);
}

{
	package Local::Class4;
	use MooseX::ArrayRef;
	use Sub::HandlesVia;
	has foo => (
		is           => 'ro',
		lazy         => 1,
		default      => sub { 665 },
		handles_via  => 'Scalar',
		handles      => {
			ref_to_foo => 'scalar_reference',
		},
	);
}

{
	package Local::Class5;
	use MooseX::InsideOut;
	use Sub::HandlesVia;
	has foo => (
		is           => 'ro',
		lazy         => 1,
		default      => sub { 665 },
		handles_via  => 'Scalar',
		handles      => {
			ref_to_foo => 'scalar_reference',
		},
	);
}

require B::Deparse;
for my $i (1 .. 5) {
	my $class = "Local::Class$i";
	note "sub $class\::ref_to_foo";
	note(B::Deparse->new->coderef2text($class->can('ref_to_foo')));
	my $obj = $class->new();
	my $ref = $obj->ref_to_foo;
	is(ref($ref), 'SCALAR');
	++$$ref;
	is($obj->foo, 666);
}


done_testing;