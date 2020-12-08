use strict;
use warnings;
use Test::More;
use Number::Fraction;

my $f = eval { Number::Fraction->new('1/0') };
ok($@, "Denominator of zero should not allowed in string" );

$f = eval { Number::Fraction->new(1 , 0 ) };
ok($@, "Denominator of zero should not allowed in two ints" );

my $zero = Number::Fraction->new (0);
cmp_ok($zero, '==', 0, "created a 'zero' fraction");

my $qrtr = Number::Fraction->new('1/4');
cmp_ok($qrtr, '==', 0.25, "Created 1/4");

my $divz = eval { $qrtr / $zero };
ok($@, "Division by zero should cause FATAL ERROR");

done_testing();
