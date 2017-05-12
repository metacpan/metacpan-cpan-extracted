#!perl

use strict;
use warnings;

use Benchmark qw(cmpthese);

use Math::GMP;
use Math::BigInt;
Math::BigInt->accuracy(60);

use Number::AnyBase;
use Math::BaseConvert qw(cnv);
use Math::Base::Convert;
use Math::BaseCalc;

use constant {
    MAX_NATIVE_INT   => 4_000_000_000,
    NUMBERS          => 10_000,
    TEST_REPETITIONS => 10,
    ALPHABET         => [0..9, 'A'..'Z', 'a'..'z']
};

$| = 1;

my $alphabet_size = @{ &ALPHABET };

my $number_anybase = Number::AnyBase->new(ALPHABET);

my @dec_numbers;
push @dec_numbers, int rand MAX_NATIVE_INT for 1..NUMBERS;
my @base_numbers = map $number_anybase->to_base($_), @dec_numbers;

my @big_dec_numbers = qw(
    123456789012345678901234567890123456789012345678901234567890
    234567890123456789012345678901234567890123456789012345678901
    345678901234567890123456789012345678901234567890123456789012
    456789012345678901234567890123456789012345678901234567890123
    567890123456789012345678901234567890123456789012345678901234
    678901234567890123456789012345678901234567890123456789012345
    789012345678901234567890123456789012345678901234567890123456
    890123456789012345678901234567890123456789012345678901234567
    901234567890123456789012345678901234567890123456789012345678
    123456789012345678901234567890123456789012345678901234567890
    234567890123456789012345678901234567890123456789012345678901
    345678901234567890123456789012345678901234567890123456789012
    456789012345678901234567890123456789012345678901234567890123
    567890123456789012345678901234567890123456789012345678901234
    678901234567890123456789012345678901234567890123456789012345
    789012345678901234567890123456789012345678901234567890123456
    890123456789012345678901234567890123456789012345678901234567
    901234567890123456789012345678901234567890123456789012345678
);
my @big_base_numbers = map $number_anybase->to_base($_), @big_dec_numbers;

my $math_basecalc = Math::BaseCalc->new( digits => ALPHABET );
my $math_base_convert_2base = Math::Base::Convert->new(10, ALPHABET);
my $math_base_convert_2dec = Math::Base::Convert->new(ALPHABET, 10);

print 'Random native decimals to base', "\n";
cmpthese( TEST_REPETITIONS, {
    'Math::BaseConvert::cnv' => sub { cnv($_, 10, $alphabet_size)       foreach @dec_numbers },
    'Math::Base::Convert'    => sub { $math_base_convert_2base->cnv($_) foreach @dec_numbers },
    'Math::BaseCalc'         => sub { $math_basecalc->to_base($_)       foreach @dec_numbers },
    'Number::AnyBase'        => sub { $number_anybase->to_base($_)      foreach @dec_numbers }
});

print "\n";

print 'Random base numbers to native decimals', "\n";
cmpthese( TEST_REPETITIONS, {
    'Math::BaseConvert::cnv' => sub { cnv($_, $alphabet_size, 10)      foreach @base_numbers },
    'Math::Base::Convert'    => sub { $math_base_convert_2dec->cnv($_) foreach @base_numbers },
    'Math::BaseCalc'         => sub { $math_basecalc->from_base($_)    foreach @base_numbers },
    'Number::AnyBase'        => sub { $number_anybase->to_dec($_)      foreach @base_numbers }
});

print "\n";

print 'Random big decimals to base', "\n";
cmpthese( TEST_REPETITIONS * 10, {
    'Math::BaseConvert::cnv' => sub { cnv($_, 10, $alphabet_size)                    foreach @big_dec_numbers },
    'Math::Base::Convert'    => sub { $math_base_convert_2base->cnv($_)              foreach @big_dec_numbers },
    'Number::AnyBase'        => sub { $number_anybase->to_base( Math::GMP->new($_) ) foreach @big_dec_numbers }
});

print "\n";

print 'Random big base numbers to decimals', "\n";
cmpthese( TEST_REPETITIONS * 10, {
    'Math::BaseConvert::cnv' => sub { cnv($_, $alphabet_size, 10)                   foreach @big_base_numbers },
    'Math::Base::Convert'    => sub { $math_base_convert_2dec->cnv($_)              foreach @big_base_numbers },
    'Number::AnyBase'        => sub { $number_anybase->to_dec( $_, Math::GMP->new ) foreach @big_base_numbers }
});

print "\n";

print 'Constructors', "\n";
cmpthese( TEST_REPETITIONS, {
    'Math::BaseCalc::new()'      => sub { Math::BaseCalc->new( digits => ALPHABET ) for 1..NUMBERS },
    'Math::Base::Convert::new()' => sub { Math::Base::Convert->new(10, ALPHABET)    for 1..NUMBERS },
    'Number::AnyBase::fastnew()' => sub { Number::AnyBase->fastnew(ALPHABET)        for 1..NUMBERS }
});
