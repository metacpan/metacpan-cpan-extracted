use strict;
use warnings;
use Test::More;
use Test::Fatal;
{
	package My::Connection;
	use Moose;

	has type => (
		is => 'ro',
		isa => 'Str',
		default => sub { 'Type1' },
		lazy => 1,
	);
}

{
	package My::Factory::Implementation;
	use Moose;

	around BUILDARGS => sub {
		my ( $orig, $self, $conn ) = @_;

		$self->$orig({ connection => $conn->type });
	};

	has connection => (is => 'ro', isa => 'Str');

	sub tweak { 1; };
}

{
	package My::Factory;
	use MooseX::AbstractFactory;
	use Moose;
}

my $connection = My::Connection->new;

my $imp;
my $e0
	= exception {
		$imp = My::Factory->create( 'Implementation', $connection );
	};

is $e0, undef, "Factory->new() doesn't die";

isa_ok($imp, "My::Factory::Implementation");

can_ok($imp, qw/tweak/);
is($imp->tweak(),1,"tweak returns 1");
is($imp->connection(), 'Type1', 'connection attr set by constructor');

my $e1 = exception { $imp->fudge(); };
like $e1, qr/^Can't locate object method/,
	"fudge dies, not implemented on implementor";

done_testing;
