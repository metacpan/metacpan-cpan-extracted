use Test::More;
use strict;
use warnings;

use Rstats;

# skip test on openbsd because openbsd srand and rand can't ensure reproducibility
if($^O eq 'openbsd') {
  plan skip_all => 'Skip test on openbsd';
}
else {
  plan 'no_plan';
}

# runif
{
  {
    srand 100;
    my $rands = [rand 1, rand 1, rand 1, rand 1, rand 1];
    r->set_seed(100);
    my $x1 = r->runif(5);
    is_deeply($x1->values, $rands);
    
    my $x2 = r->runif(5);
    isnt($x1->values->[0], $x2->values->[0]);

    my $v3 = r->runif(5);
    isnt($x2->values->[0], $v3->values->[0]);
    
    my $v4 = r->runif(100);
    my @in_ranges = grep { $_ >= 0 && $_ <= 1 } @{$v4->values};
    is(scalar @in_ranges, 100);
  }
  
  # runif - min and max
  {
    srand 100;
    my $rands = [
      rand(9) + 1,
      rand(9) + 1,
      rand(9) + 1,
      rand(9) + 1,
      rand(9) + 1
    ];
    r->set_seed(100);
    my $x1 = r->runif(5, 1, 10);
    is_deeply($x1->values, $rands);

    my $x2 = r->runif(100, 1, 2);
    my @in_ranges = grep { $_ >= 1 && $_ <= 2 } @{$x2->values};
    is(scalar @in_ranges, 100);
  }
}
