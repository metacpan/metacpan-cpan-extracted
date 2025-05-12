use Test::More;
use Number::Equation::XS;
my $n = Number::Equation::XS->new(42, .01);
$n = $n - 2;
$n /= 10;
$n *= 2;
$n += 2;
my $m = 1 / $n;

is($m->equation, '(1 / ((((42 - 2) / 10) * 2) + 2)) ≈ 0.1');

my $x = 2 - $m;
is($x->equation, '(2 - (1 / ((((42 - 2) / 10) * 2) + 2))) ≈ 1.9');

$n = Number::Equation::XS->new(1, 0.01);
$n /= 4;
is($n->equation, '(1 / 4) ≈ 0.25');

$n = Number::Equation::XS->new(50, 0);
$n = $n % 2;
is($n, 0);
is($n->equation, '(50 % 2) = 0');
$n = Number::Equation::XS->new(50, 0);
$n = $n ** 2;
is($n, 2500);
is($n->equation, '(50 ** 2) = 2500');


done_testing();
