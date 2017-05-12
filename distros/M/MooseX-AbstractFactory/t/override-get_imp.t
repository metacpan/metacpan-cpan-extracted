use Test::More;
use Test::Moose;
use Test::Fatal;

BEGIN {
	package Bar::Implementation;
	use Moose;

	has connection => (is => 'ro', isa => 'Str');

	sub tweak { 1; };

	package My::Factory;
	use MooseX::AbstractFactory;

	sub _get_implementation_class {
		my ($self, $impl) = @_;

		return "Bar::" . $impl;
	}
}

my $imp;

my $e0 = exception {
	$imp = My::Factory->create(
		'Implementation',
		{ connection => 'Type1' }
	);
};

is $e0, undef, "Factory->new() doesn't die";

isa_ok($imp, "Bar::Implementation");

done_testing;
