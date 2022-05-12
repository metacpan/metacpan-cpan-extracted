use Test::More;
use Number::Equation;
my $n = Number::Equation->new(42, .01);
$n = $n - 2;
$n /= 10;
$n *= 3;
$n += 1;
my $m = 1 / $n;
is($m->equation, '(1 / ((((42 - 2) / 10) * 3) + 1)) ≈ 0.08');
my $x = 2 - $m;
is($m->equation, '(2 - (1 / ((((42 - 2) / 10) * 3) + 1))) ≈ 1.92');

done_testing();
