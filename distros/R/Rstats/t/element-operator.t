use Test::More 'no_plan';
use strict;
use warnings;

ok(1);

=pod
{
  # operator - +
  {
    my $na = Rstats::Util::NA;
    my $ret = $na + 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # operator - -
  {
    my $na = Rstats::Util::NA;
    my $ret = $na - 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # operator - *
  {
    my $na = Rstats::Util::NA;
    my $ret = $na * 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # operator - /
  {
    my $na = Rstats::Util::NA;
    my $ret = $na / 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # operator - **
  {
    my $na = Rstats::Util::NA;
    my $ret = $na ** 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # operator - %
  {
    my $na = Rstats::Util::NA;
    my $ret = $na % 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # operator - negation
  {
    my $na = Rstats::Util::NA;
    my $ret = -$na;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # operator - <
  {
    my $na = Rstats::Util::NA;
    my $ret = $na < 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # operator - <=
  {
    my $na = Rstats::Util::NA;
    my $ret = $na <= 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # operator - >
  {
    my $na = Rstats::Util::NA;
    my $ret = $na > 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # operator - >=
  {
    my $na = Rstats::Util::NA;
    my $ret = $na >= 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # operator - ==
  {
    my $na = Rstats::Util::NA;
    my $ret = $na == 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # operator - !=
  {
    my $na = Rstats::Util::NA;
    my $ret = $na != 1;
    is(ref $ret, 'Rstats::Element::NA');
  }
}

# numeric operator 
{
  # numeric operator - +
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan + 1;
    is(ref $ret, 'Rstats::NaN');
  }

  # numeric operator - -
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan - 1;
    is(ref $ret, 'Rstats::NaN');
  }

  # numeric operator - *
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan * 1;
    is(ref $ret, 'Rstats::NaN');
  }

  # numeric operator - /
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan / 1;
    is(ref $ret, 'Rstats::NaN');
  }

  # numeric operator - **
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan ** 1;
    is(ref $ret, 'Rstats::NaN');
  }

  # numeric operator - %
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan % 1;
    is(ref $ret, 'Rstats::NaN');
  }

  # numeric operator - negation
  {
    my $nan = Rstats::Util::NaN;
    my $ret = -$nan;
    is(ref $ret, 'Rstats::NaN');
  }
}

# comparison operator
{
  # comparison operator - <, number
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan < 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # comparison operator - <, complex
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan < $r->complex(1,1);
    is(ref $ret, 'Rstats::Element::NA');
  }

  # comparison operator - ==, character
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan == 'a';
    is($ret, $r->FALSE);
  }

  # comparison operator - ==, character
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan == 'NaN';
    is($ret, $r->TRUE);
  }
  
  # comparison operator - <=
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan <= 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # comparison operator - >
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan > 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # comparison operator - >=
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan >= 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # comparison operator - ==
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan == 1;
    is(ref $ret, 'Rstats::Element::NA');
  }

  # comparison operator - !=
  {
    my $nan = Rstats::Util::NaN;
    my $ret = $nan != 1;
    is(ref $ret, 'Rstats::Element::NA');
  }
}

=cut
