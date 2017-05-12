#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    unless ( eval 'use Math::BigInt; 1' ) {
        plan skip_all => "Math::BigInt required to run these tests"
    }
    unless ( eval 'use Math::GMP; 1' ) {
        plan skip_all => "Math::GMP required to run these tests"
    }
}

Math::BigInt->accuracy(60);

use constant {
    BIG_DEC => '123456789012345678901234567890123456789012345678901234567890',
    INCREMENTS => 50_000
};

use Number::AnyBase;

plan tests => 4;

my $conv = Number::AnyBase->new_base62;

my $base_num;
my $result;
my $next_num;
my $prev_num;

$base_num = $conv->to_base( Math::BigInt->new(BIG_DEC) );

is $result = $conv->to_dec( $base_num, Math::BigInt->new ), BIG_DEC,
    "Roundtrip ${ \BIG_DEC } > $base_num > ${ \BIG_DEC } (Math::BigInt)";

$next_num = $base_num;
$next_num = $conv->next($next_num) for 1..INCREMENTS;

is $next_num, $conv->to_base($result + INCREMENTS), 'Bignum native increments';

$prev_num = $next_num;
$prev_num = $conv->prev($prev_num) for 1..INCREMENTS;

is $prev_num, $base_num, 'Bignum native decrements';

$base_num = $conv->to_base( Math::GMP->new(BIG_DEC) );

ok $result = $conv->to_dec( $base_num, Math::GMP->new ) == BIG_DEC,
    "Roundtrip ${ \BIG_DEC } > $base_num > ${ \BIG_DEC } (Math::GMP)";
