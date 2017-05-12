#! /usr/bin/perl -w

use strict;

use Test::More tests => 9;

use Number::Convert;

my $number = new Number::Convert(1024);

ok( defined $number, 'new() returned an object' );
ok( $number->isa('Number::Convert'), 'and it\'s the right class' );
is( $number->ToDecimal(), 1024, 'The decimal value is 1024');
is( $number->ToBinary(), 10000000000, 'The binary value is 10000000000');
is( $number->ToHex(), 400, 'The hexa-decimal value is 400');
is( $number->ToOctal(), 2000, 'The octal value is 2000');

$number /= 4;
$number -= 1;

is( $number->ToDecimal(), 255, 'The decimal value is now 255');

is( $number->ToHex(), 'ff', 'The hexa-decimal value is ff');
is( $number->ToUpperCaseHex(), 'FF', 'The hexa-decimal value in uppercase is FF');
