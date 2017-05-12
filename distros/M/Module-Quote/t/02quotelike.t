use Test::More tests => 2;
use Module::Quote qw( qm qp );

my $number1 = qm( Math::BigInt )->new(42);
my $number2 = qp( Math::BigInt 1.00 )->new(42);

isa_ok $number1, "Math::BigInt";
isa_ok $number2, "Math::BigInt";
