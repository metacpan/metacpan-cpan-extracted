use strict;
use warnings;

use Params::Validate::Dependencies qw(:all);

use Test::More;
END { done_testing(); }

# gamma is compulsory, must have one of alpha/beta
my %pv = (
  alpha => { type => SCALAR,  optional => 1 },
  beta  => { type => SCALAR,  optional => 1 },
  gamma => { type => SCALAR,  optional => 0 },
);

my @pvd = all_of('gamma', one_of(qw(alpha beta)));

is_deeply(
  scalar(pvd_only(alpha => 1, gamma => 2)),
  {alpha => 1, gamma => 2},
  "correct return value in scalar context with P::V::D checking only"
);
is_deeply(
  scalar(pvd_only(alpha => 1, gamma => 2)),
  {alpha => 1, gamma => 2},
  "correct return value in list context with P::V::D checking only"
);

is_deeply(
  scalar(both(alpha => 1, gamma => 2)),
  {alpha => 1, gamma => 2},
  "correct return value in scalar context with both P::V and P::V::D checking"
);
is_deeply(
  scalar(both(alpha => 1, gamma => 2)),
  {alpha => 1, gamma => 2},
  "correct return value in list context with both P::V and P::V::D checking"
);

sub pvd_only { return wantarray ? (validate(@_,       @pvd)) : scalar(validate(@_,       @pvd)); }
sub both     { return wantarray ? (validate(@_, \%pv, @pvd)) : scalar(validate(@_, \%pv, @pvd)); }
