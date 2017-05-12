use Test::More tests => 4;

use strict;
use warnings;

BEGIN {
  use_ok("Number::Tolerant");
  use_ok("Number::Tolerant::Type");
}

{
  package Number::Tolerant::Type::through;
  use base qw(Number::Tolerant::Type);

  sub construct { shift;
    ($_[0],$_[1]) = sort { $a <=> $b } ($_[0],$_[1]);
    {
      value    => ($_[0]+$_[1])/2,
      variance => $_[1] - ($_[0]+$_[1])/2,
      min      => $_[0],
      max      => $_[1]
    }
  }

  sub parse {
    my $self = shift;
    my $number = $self->number_re;

    tolerance("$1", 'through', "$2") if ($_[0] =~ m!\A($number) to ($number)\Z!)
  }

  sub stringify { "$_[0]->{min} through $_[0]->{max}" }

  sub valid_args {
    my $self = shift;
    my $number = $self->number_re;

    return ($_[0],$_[2])
      if ((grep { defined } @_) == 3)
      and ($_[0] =~ $number) and ($_[1] eq 'through') and ($_[2] =~ $number);
    return;
  }

  Number::Tolerant->enable_plugin("Number::Tolerant::Type::through");
}

isa_ok(
  tolerance(8 => through => 10),
  'Number::Tolerant'
);

ok(
  9 == tolerance(8 => through => 10),
  "'through' tolerance works, trivially"
);
