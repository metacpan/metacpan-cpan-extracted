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

	implementation_does qw/My::Role/;

	#----------------------------------------------------
	# My::Role requires tweak()
	package My::Role;
	use Moose::Role;
	requires 'tweak';
}

my $e0
	= exception {
		My::Factory->create( ImplementationA => { connection => 'Type1'});
	};

my $e1
	= exception {
		My::Factory->create( ImplementationB => {} );
	};

is   $e0, undef, "Factory->new() doesn't die with ImplementationA";
like $e1, qr/^Invalid implementation class My::Factory::ImplementationB/,
	'Factory->new() dies with implementationB';

done_testing;
