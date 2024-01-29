use strict;
use warnings;

use Params::Validate::Dependencies qw(:all exclusively);

use Test::More;
use Test::Exception;
END { done_testing(); }

sub doc { Params::Validate::Dependencies::document(@_) }

my $any_of = any_of(
  qw(alpha beta),
  'key with spaces',
  "single'quote",
  all_of(qw(foo bar), none_of('barf')),
  one_of(qw(quux garbleflux))
);
my $exclusively =  exclusively($any_of);

my @args = (bollocks => 1, foo => 1, bar => 1);
ok(
  validate(@args, $any_of),
  "passing random bollocks when exclusively() isn't used validates in PVD"
);
dies_ok(
  sub { validate(@args, $exclusively) },
  'exclusively fails when excess baggage present using PVD'
);
like($@, qr/code-ref checking failed/, "... died correctly");
@args = (foo => 1, bar => 1);
ok(
  validate(@args, $exclusively),
  'exclusively passes when no excess baggage present using PVD'
);

is(
  doc($exclusively),
  "exclusively (any of ('alpha', 'beta', 'key with spaces', 'single\\'quote', all of ('foo', 'bar' and none of ('barf')) or one of ('quux' or 'garbleflux')))",
  "doco for exclusively() works in PVD"
);

SKIP: {
  skip "Data::Domain requires perl 5.18 or higher" if($] <= 5.018);
  note("Now let's try with Data::Domain::Dependencies");

  eval 'use Data::Domain::Dependencies qw(:all)';
  
  my $domain = Dependencies($any_of);
  ok(!$domain->inspect({ bollocks => 1, foo => 1, bar => 1 }),
    "passing random bollocks when exclusively() isn't used validates in DDD");
  
  $domain = Dependencies($exclusively);
  ok(
    !$domain->inspect({ foo => 1, bar => 1 }),
    'exclusively() passes when no excess baggage is present using DDD'
  );
  ok(
    $domain->inspect({ bollocks => 1, foo => 1, bar => 1 }),
    'exclusively() fails when excess baggage is present using DDD'
  );
}
