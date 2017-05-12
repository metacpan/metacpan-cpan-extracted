use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;

# NA
{

  # NA - 129 count
  {
    my $x1 = c_(1);
    my $x2 = array(NA, 129);
    my $x3 = $x1 + $x2;
    is_deeply($x3->values, [(undef) x 129]);
  }
  
  # NA - double + NA
  {
    my $x1 = c_(1);
    my $x2 = array(NA, 128);
    my $x3 = $x1 + $x2;
    is_deeply($x3->values, [(undef) x 128]);
  }

  # NA - NA + NA
  {
    my $x1 = array(NA, 128);
    my $x2 = array(NA, 128);
    my $x3 = $x1 + $x2;
    is_deeply($x3->values, [(undef) x 128]);
  }
  
  # NA - NA + double
  {
    my $x1 = array(NA, 128);
    my $x2 = c_(1);
    my $x3 = $x1 + $x2;
    is_deeply($x3->values, [(undef) x 128]);
  }
}
  