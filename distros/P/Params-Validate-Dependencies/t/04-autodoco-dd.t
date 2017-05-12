use strict;
use warnings;

use Test::More (
    $] <= 5.010 ? (skip_all => 'only on perl 5.10 and higher') : ()
);
END { done_testing(); }

use Data::Domain::Dependencies qw(:all);

my $domain = Dependencies(
  any_of(
    qw(alpha beta),
    all_of(qw(foo bar), none_of('barf')),
    one_of(qw(quux garbleflux))
  )
);

is(
  $domain->generate_documentation(),
  "any of ('alpha', 'beta', all of ('foo', 'bar' and none of ('barf')) or one of ('quux' or 'garbleflux'))",
  "Data::Domain::Dependencies doco also works"
);
