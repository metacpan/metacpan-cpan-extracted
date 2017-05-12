use strict;
use warnings;
use Test::More;

my $init;

{
	package Foo;
	
	use Moose;
	use MooseX::CustomInitArgs;
	
	has foo => (
		is        => 'ro',
		init_args => [
			'fu',
			'comfute' => \'_init_comfute',
		],
	);
	
	sub _init_comfute
	{
		$init++;
		return $_;
	}
}

sub check ($$)
{
	my ($args, $name) = @_;
	is(Foo->new(@$args)->foo, 42, $name);
}

check [foo     => 42], 'mutable class; standard init arg';
check [fu      => 42], 'mutable class; alternative init arg';
check [comfute => 42], 'mutable class; alternative init arg (with coderef)';

Foo->meta->make_immutable;

check [foo     => 42], 'immutable class; standard init arg';
check [fu      => 42], 'immutable class; alternative init arg';
check [comfute => 42], 'immutable class; alternative init arg (with coderef)';

is $init, 2;

done_testing;
