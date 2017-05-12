use Test::More tests => 5;
use Number::Fraction ':constants';

my $f = '1/2';
my $f2 = '1/16';
my $f3 = '2/1';

is($f ** 2, '1/4', 'Raising Number::Fraction to an integer power');
is($f ** 3, '1/8', 'Raising Number::Fraction to another interger power');
is(4 ** $f, 2, 'Raising an integer to a Number::Fraction');
is($f2 ** $f, 0.25, 'Raising a Number::Fraction to a Number::Fraction');
is($f ** $f3, '1/4', 'Raising a Number::Fraction to a Number::Fraction that is really an integer');
