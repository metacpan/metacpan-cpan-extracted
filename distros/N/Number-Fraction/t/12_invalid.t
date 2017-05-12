use Test::More 'no_plan';
use Number::Fraction;

my $f = eval { Number::Fraction->new("\x{555}") };
ok($@);

$f = eval { Number::Fraction->new("\x{666}") };
ok($@);

$f = eval { Number::Fraction->new("6\n") };
ok($@);

$f = eval {Number::Fraction->new("6\n\n") };
ok($@);
