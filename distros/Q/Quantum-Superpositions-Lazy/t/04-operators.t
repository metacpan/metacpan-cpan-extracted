use v5.24; use warnings;
use Test::More;
use Quantum::Superpositions::Lazy;

##############################################################################
# Here we're checking if all the operators yield the right results, but
# we don't care for the collapsing stuff anymore
##############################################################################

my $a1 = superpos(6);
my $a2 = superpos(3);
my $a3;

is "$a1", 6, "stringification ok";
is -$a1, -6, "negation ok";

is $a1 . $a2, 63, "concatenation ok";
$a3 = $a1; $a3 .= $a2;
is $a3, 63, "concatenation ok";

is $a1 x 3, 666, "string repetition ok";
$a3 = $a1; $a3 x= 3;
is $a3, 666, "string repetition ok";

is $a1 + $a2, 9, "addition ok";
$a3 = $a1; $a3 += $a2;
is $a3, 9, "addition ok";

is $a1 - $a2, 3, "subtraction ok";
$a3 = $a1; $a3 -= $a2;
is $a3, 3, "subtraction ok";

is $a1 * $a2, 18, "multiplication ok";
$a3 = $a1; $a3 *= $a2;
is $a3, 18, "multiplication ok";

is $a1 / $a2, 2, "division ok";
$a3 = $a1; $a3 /= $a2;
is $a3, 2, "division ok";

is $a1 % $a2, 0, "modulo ok";
$a3 = $a1; $a3 %= $a2;
is $a3, 0, "modulo ok";

is $a1 ** $a2, 216, "power ok";
$a3 = $a1; $a3 **= $a2;
is $a3, 216, "power ok";

is $a1 << $a2, 48, "shift left ok";
$a3 = $a1; $a3 <<= $a2;
is $a3, 48, "shift left ok";

is $a1 >> 1, 3, "shift right ok";
$a3 = $a1; $a3 >>= 1;
is $a3, 3, "shift right ok";

is atan2($a1, $a2), atan2(6, 3), "atan2 ok";
is cos($a1), cos(6), "cos ok";
is sin($a1), sin(6), "sin ok";
is exp($a1), exp(6), "exp ok";
is log($a1), log(6), "log ok";
is sqrt($a1), sqrt(6), "sqrt ok";
is int($a1 + 0.5), 6, "int ok";
is abs(8 - $a1), 2, "abs ok";

done_testing;
