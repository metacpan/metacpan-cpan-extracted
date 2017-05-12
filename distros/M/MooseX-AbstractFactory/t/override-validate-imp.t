use strict;
use warnings;
use Test::More;
use Test::Fatal;

BEGIN {
	#----------------------------------------------------
	package My::Implementation;
	use Moose;

	#----------------------------------------------------
	# Factory class, all implementations valid
	package My::FactoryA;
	use MooseX::AbstractFactory;

	implementation_class_via sub { "My::Implementation" };

	sub _validate_implementation_class {
		return;
	}

	#----------------------------------------------------
	# Factory class, all implementations invalid
	package My::FactoryB;
	use MooseX::AbstractFactory;

	implementation_class_via sub { "My::Implementation" };

	sub _validate_implementation_class {
		confess "invalid implementation";
	}

}

my $e0
	= exception {
		My::FactoryA->create('Implementation', {});
	};

is $e0, undef, "FactoryA->new() doesn't die with Implementation";


my $e1
	= exception {
		My::FactoryB->create( 'Implementation', {} );
	};

like $e1, qr/^invalid implementation/, "FactoryB->new() dies with implementation";

done_testing;
