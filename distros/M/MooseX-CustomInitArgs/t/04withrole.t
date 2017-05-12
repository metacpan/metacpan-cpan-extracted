use strict;
use warnings;
use Test::More;

{
	package Foo;
	
	use Moose::Role;
	use MooseX::CustomInitArgs;
	
	has foo => (
		is        => 'ro',
		init_args => ['fu', 'comfute' => sub { $_ }],
	);
}

{
	package Bar;
	use Moose;
	with 'Foo';
	has bar => (is => 'ro');
}

sub check ($$)
{
	my ($args, $name) = @_;
	is(Bar->new(@$args)->foo, 42, "$name");
}

check [foo     => 42], 'mutable class; standard init arg';
check [fu      => 42], 'mutable class; alternative init arg';
check [comfute => 42], 'mutable class; alternative init arg (with coderef)';

Bar->meta->make_immutable;

check [foo     => 42], 'immutable class; standard init arg';
check [fu      => 42], 'immutable class; alternative init arg';
check [comfute => 42], 'immutable class; alternative init arg (with coderef)';

{
	package Quux1;
	use Moose::Role;
	with 'Foo';
}

{
	package Quux2;
	use Moose::Role;
	with 'Quux1';
}

{
	package Quux3;
	use Moose::Role;
	with 'Quux2';
}

{
	package Baz;
	use Moose;
	with 'Quux3';
}

sub checkz ($$)
{
	my ($args, $name) = @_;
	is(Baz->new(@$args)->foo, 99, "$name");
}

checkz [foo     => 99], 'mutable class, indirected through role chain; standard init arg';
checkz [fu      => 99], 'mutable class, indirected through role chain; alternative init arg';
checkz [comfute => 99], 'mutable class, indirected through role chain; alternative init arg (with coderef)';

Baz->meta->make_immutable;

checkz [foo     => 99], 'immutable class, indirected through role chain; standard init arg';
checkz [fu      => 99], 'immutable class, indirected through role chain; alternative init arg';
checkz [comfute => 99], 'immutable class, indirected through role chain; alternative init arg (with coderef)';

done_testing;
