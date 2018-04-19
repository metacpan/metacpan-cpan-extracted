use Test::More 'no_plan';
use strict;
use warnings;

use Rstats::Util;
use Scalar::Util 'refaddr';

# logical
{
  # logical - singleton, true
  {
    my $true1 = Rstats::Util::TRUE;
    my $true2 = Rstats::Util::TRUE;
    is(refaddr $true1, refaddr $true2);
  }
  
  # logical - singleton, false
  {
    my $false1 = Rstats::Util::FALSE;
    my $false2 = Rstats::Util::FALSE;
    is(refaddr $false1, refaddr $false2);
  }
  
  # logical - bool, TRUE
  {
    my $true = Rstats::Util::TRUE;
    ok($true);
  }
  
  # logical - bool, FALSE
  {
    my $false = Rstats::Util::FALSE;
    ok(!Rstats::Util::bool($false));
  }
  
  # negation, true
  {
    my $true = Rstats::Util::TRUE;
    my $num = Rstats::Util::negation($true);
    ok(Rstats::Util::is_integer($num));
    is($num->value, -1);
  }

  # negation, false
  {
    my $false = Rstats::Util::FALSE;
    my $num = Rstats::Util::negation($false);
    ok(Rstats::Util::is_integer($num));
    is($num->value, 0);
  }
  
  # to_string, true
  {
    my $true = Rstats::Util::TRUE;
    is(Rstats::Util::to_string($true), 'TRUE');
  }
  
  # to_string, false
  {
    my $false = Rstats::Util::FALSE;
    is(Rstats::Util::to_string($false), "FALSE");
  }
}

