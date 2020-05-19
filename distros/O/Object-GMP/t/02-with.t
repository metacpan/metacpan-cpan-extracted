{package Foo;
    use Moo;

    with "Object::GMP";

    has a     => ( is => 'ro' );
    has b     => ( is => 'ro' );
    has prime => ( is => 'rw' );

    around BUILDARGS => __PACKAGE__->BUILDARGS_val2gmp('prime');
}

use strict;
use warnings;
use Test::More;

my $prime =
  '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F';

my $foo = Foo->new( a => 0, b => 7, prime => $prime );

isnt( ref( $foo->a ), undef, 'a is not gmp' );
isnt( ref( $foo->b ), undef, 'b is not gmp' );
isa_ok( $foo->prime, 'Math::BigInt', 'prime is gmp' );

my $bar = $foo->copy( a => 4 );

is_deeply(
    $bar->hashref,
    {
        a     => 4,
        b     => 7,
        prime => $prime,
    },
    'copy foo to bar with different a value'
);

$bar->prime($bar->prime * -1);

is_deeply(
    $bar->hashref,
    {
        a     => 4,
        b     => 7,
        prime => "-$prime",
    },
    'neg prime value'
);

is_deeply(
    $bar->hashref(keep => ['prime']),
    {
        a     => 4,
        b     => 7,
        prime => Math::BigInt->new('-115792089237316195423570985008687907853269984665640564039457584007908834671663'),
    },
    'neg prime value in true form'
);

done_testing;
