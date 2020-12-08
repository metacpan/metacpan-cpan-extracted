use strict;
use warnings;
use Test::More;
use Number::Fraction ':constants';

my $fract = undef;

$fract = eval { Number::Fraction->new(3.0 , 4) };
cmp_ok($fract, 'eq' , '3/4', "fraction from round decimal numerator as number");

$fract = eval {Number::Fraction->new(3 , 4.0) };
cmp_ok($fract, 'eq' , '3/4',
       "fraction from round decimal denominator as number");

$fract = eval {Number::Fraction->new('3', '4' ) };
ok(!$@, "fraction from two healthy strings now supported");

$fract = eval {Number::Fraction->new('3.0', '4' ) };
ok(!$@, "fraction from round decimal numerator as string now supported");

$fract = eval {Number::Fraction->new('3' , '4.0') };
ok(!$@, "fraction from round decimal denominator as string now supported");

$fract = eval {Number::Fraction->new(3.5, 4 ) };
ok($@, "Numerator can't be a decimal");

$fract = eval {Number::Fraction->new(3 , 4.5) };
ok($@, "Denominator can't be a decimal");

done_testing();
