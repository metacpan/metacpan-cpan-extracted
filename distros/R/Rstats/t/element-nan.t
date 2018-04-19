use Test::More 'no_plan';
use strict;
use warnings;

use Rstats::Util;

# nan - singleton
{
  my $nan1 = Rstats::Util::NaN;
  my $nan2 = Rstats::Util::NaN;
  is($nan1, $nan2);
}

# nan - nan is double
{
  my $nan = Rstats::Util::NaN;
  ok(Rstats::Util::is_double($nan));
}

# negation
{
  my $nan1 = Rstats::Util::NaN;
  my $nan2 = Rstats::Util::negation($nan1);
  ok(Rstats::Util::is_nan($nan2));
}

# non - boolean
{
  my $nan = Rstats::Util::NaN;
  eval { Rstats::Util::bool($nan) };
  like($@, qr/logical/);
}

# non - to_string
{
  my $nan = Rstats::Util::NaN;
  is(Rstats::Util::to_string($nan), 'NaN');
}

