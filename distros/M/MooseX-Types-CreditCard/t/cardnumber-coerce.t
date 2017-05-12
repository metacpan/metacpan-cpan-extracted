use strict;
use warnings;
use Test::More;

{
	package Credit;
	use Moose;
	use MooseX::Types::CreditCard qw( CardNumber CreditCard );

	has debit => (
		isa    => CardNumber,
		is     => 'ro',
		coerce => 1,
	);

	has credit => (
		isa    => CreditCard,
		is     => 'ro',
		coerce => 1,
	);

	__PACKAGE__->meta->make_immutable;
}

my $c0 = new_ok( Credit => [{ debit  => '4111-1111-1111-1111' }]);
my $c1 = new_ok( Credit => [{ credit => '4111-1111-1111-1111' }]);

is( $c0->debit,  '4111111111111111', 'CardNumber' );
is( $c1->credit, '4111111111111111', 'CreditCard' );

done_testing;
