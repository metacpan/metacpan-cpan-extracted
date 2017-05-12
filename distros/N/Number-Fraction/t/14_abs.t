use Test::More;
use Number::Fraction ':constants';

my $f = '-1/2';
my $f2 = '1/16';
my $f3 = '2/-1';

is(abs($f), '1/2', 'Abs on a negative numerator');
cmp_ok(abs($f), '==', 0.5, 'Numeric abs on a negative numerator');
is(abs($f2), '1/16', 'Abs on a positive fraction');
cmp_ok(abs($f2), '==', 0.0625, 'Numeric abs on a positive fraction');
is(abs($f3), '2/1', 'Abs on a negative denominator');
cmp_ok(abs($f3), '==', 2, 'Numeric abs on a negative denominator');

done_testing;
