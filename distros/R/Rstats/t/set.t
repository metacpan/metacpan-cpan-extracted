use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;

# set 3-dimention
{
  # set 3-dimention
  {
    my $x1 = array(C_('1:24'), c_(4, 3, 2));
    my $x2 = $x1->at(4, 3, 2)->set(25);
    is_deeply($x2->values, [1 .. 23, 25]);
  }

  # set 3-dimention - one and tow dimention
  {
    my $x1 = array(C_('1:24'), c_(4, 3, 2));
    my $x2 = $x1->at(4, 3)->set(25);
    is_deeply($x2->values, [1 .. 11, 25, 13 .. 23, 25]);
  }

  # set 3-dimention - one and tow dimention, value is two
  {
    my $x1 = array(C_('1:24'), c_(4, 3, 2));
    my $x2 = $x1->at(4, 3)->set(c_(25, 26));
    is_deeply($x2->values, [1 .. 11, 25, 13 .. 23, 26]);
  }
  
  # set 3-dimention - one and three dimention, value is three
  {
    my $x1 = array(C_('1:24'), c_(4, 3, 2));
    my $x2 = $x1->at(2, c_(), 1)->set(c_(31, 32, 33));
    is_deeply($x2->values, [1, 31, 3, 4, 5, 32, 7, 8, 9, 33, 11 .. 24]);
  }
}

