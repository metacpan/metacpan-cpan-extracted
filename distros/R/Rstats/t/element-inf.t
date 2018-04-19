use Test::More 'no_plan';
use strict;
use warnings;

use Rstats::Util;
use Scalar::Util 'refaddr';

# Inf
{
  # Inf - singleton
  {
    my $inf = Rstats::Util::Inf;
    my $inf2 = Rstats::Util::Inf;
  
    is(refaddr $inf, refaddr $inf2);
  }
  
  # Inf - singleton, minus
  {
    my $inf = Rstats::Util::Inf;
    my $negative_inf = Rstats::Util::negation($inf);
    my $negative_inf2 = Rstats::Util::negativeInf;
    is(refaddr $negative_inf, refaddr $negative_inf2);
  }
  
  # Inf - negation
  {
    my $inf = Rstats::Util::Inf;
    my $negative_inf = Rstats::Util::negation($inf);
    my $negative_inf2 = Rstats::Util::negativeInf;
    is(refaddr $negative_inf, refaddr $negative_inf2);
  }

  # Inf - negation repeat
  {
    my $inf = Rstats::Util::Inf;
    my $negative_inf = Rstats::Util::negation($inf);
    my $inf2 = Rstats::Util::negation($negative_inf);
    is(refaddr $inf, refaddr $inf2);
  }
  
  # Inf - to_string, plus
  {
    my $inf = Rstats::Util::Inf;
    is(Rstats::Util::to_string($inf), 'Inf');
  }

  # Inf - to_string, minus
  {
    my $negative_inf = Rstats::Util::negativeInf;
    is(Rstats::Util::to_string($negative_inf), '-Inf');
  }
}

# is_infinite
{
  # is_infinite - Inf, true
  {
    my $inf = Rstats::Util::Inf;
    ok(Rstats::Util::is_infinite($inf));
  }
  
  # is_infinite - -Inf, true
  {
    my $negative_inf = Rstats::Util::negativeInf;
    ok(Rstats::Util::is_infinite($negative_inf));
  }
  
  # is_infinite - Double, false
  {
    my $num = Rstats::Element::Double->new(value => 1);
    ok(!Rstats::Util::is_infinite($num));
  }
}

# is_finite
{
  # is_finite - Inf, false
  {
    my $inf = Rstats::Util::Inf;
    ok(!Rstats::Util::is_finite($inf));
  }
  
  # is_finite - -Inf, false
  {
    my $negative_inf = Rstats::Util::negativeInf;
    ok(!Rstats::Util::is_finite($negative_inf));
  }
  
  # is_finite - Double, true
  {
    my $num = Rstats::Element::Double->new(value => 1);
    ok(Rstats::Util::is_finite($num));
  }
  
  # is_finite - Integer, true
  {
    my $num = Rstats::Element::Integer->new(value => 1);
    ok(Rstats::Util::is_finite($num));
  }
}
