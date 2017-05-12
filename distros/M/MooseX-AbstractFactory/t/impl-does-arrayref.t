use strict;
use warnings;
use Test::More;
use Test::Fatal;

BEGIN {
	#----------------------------------------------------
	# ImplementationA has a tweak() method
	package My::Factory::ImplementationA;
	use Moose;

	has connection => (is => 'ro', isa => 'Str');

	sub tweak { 1; }

	#----------------------------------------------------
	# ImplementationB doesn't have a tweak() method

	package My::Factory::ImplementationB;
	use Moose;

	sub no_tweak { 1; }

	#----------------------------------------------------
	# Factory class, has _roles() method that defines
	# the role(s) (My::Role) all implementations should satisfy
	package My::Factory;
	use MooseX::AbstractFactory;

	implementation_does [ qw/My::Role/ ];

	#----------------------------------------------------
	# My::Role requires tweak()
	package My::Role;
	use Moose::Role;
	requires 'tweak';
}

my $exc0 = exception {
	My::Factory->create('ImplementationA', {connection => 'Type1'});
};

my $exc1 = exception {
	My::Factory->create('ImplementationB', {});
};

is   $exc0, undef, "Factory->new() doesn't die with ImplementationA";
like $exc1, qr/
	Invalid\simplementation\sclass\s[\w:]+\s'[\w:]+'
	\srequires\sthe\smethod\s'\w+'\sto\sbe\simplemented\sby
	/x,
	"Factory->new() dies with implementationB";

done_testing;
