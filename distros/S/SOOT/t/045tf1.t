use strict;
use warnings;
use constant ITERS => 10;
use Test::More tests => 3*ITERS()+2;
use SOOT qw/:all/;

my $fun = TF1->new("test", "gaus(0)");
$fun->SetParameters(1., 2., 1.);

can_ok($fun, 'GetRandom');

my $num = $fun->GetRandom();
ok(defined $num and $num > -1000 and $num < 1000);

foreach my $i (1..ITERS()) {
  my $num = $fun->GetRandom(1., 3.);
  ok(defined $num);
  cmp_ok($num, '>=', 1.);
  cmp_ok($num, '<=', 3.);
}


