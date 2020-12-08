use strict;
use warnings;
use Test::More;
use Number::Fraction ':constants';
use utf8;

my $f = '1/2';
my $f2 = '1/16';
my $f3 = '2/1';

is($f ** 2, '1/4', 'Raising Number::Fraction to an integer power');
is($f ** 3, '1/8', 'Raising Number::Fraction to another interger power');
is(4 ** $f, 2, 'Raising an integer to a Number::Fraction');
is($f2 ** $f, 0.25, 'Raising a Number::Fraction to a Number::Fraction');
is($f ** $f3, '1/4', 'Raising a Number::Fraction to a Number::Fraction that is really an integer');

# is($f2 ** 0.5, '1/4', 'Raising a Number::Fraction to a float');
is('27/8' ** '2/3', 2.25, 'Raising a Number::Fraction to an interesting Number::Fraction');
is(0.25 ** '½', 0.5, 'Raising a nice decimal to a Number::Fraction');

done_testing();
