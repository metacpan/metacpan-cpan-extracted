use strict;
use warnings;
use Test::More;
use Number::Fraction ':constants';

my $f = '-1/-2';
ok(ref $f eq 'Number::Fraction');
ok($f == 0.5);
ok($f eq '1/2');

$f = '-1/2';
ok(ref $f eq 'Number::Fraction');
ok($f == -0.5);
ok($f eq '-1/2');

$f = '1/-2';
ok(ref $f eq 'Number::Fraction');
ok($f == -0.5);
ok($f eq '-1/2');

done_testing();
