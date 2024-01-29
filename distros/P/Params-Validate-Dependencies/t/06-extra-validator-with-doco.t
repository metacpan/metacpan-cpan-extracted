use strict;
use warnings;

use lib 't/lib';

use Params::Validate::Dependencies qw(:all);
use Params::Validate::Dependencies::two_of;

use Test::More;
use Test::Exception;
END { done_testing(); }

my @pvd = two_of(qw(alpha beta gamma));
ok(foo(alpha => 1, beta => 1) eq 'woot', "correct params, no code-refs");
ok(foo(gamma => 1, beta => 1) eq 'woot', "correct params, no code-refs");
dies_ok(sub { foo(alpha => 1) }, "incorrect params, not enough");
dies_ok(sub { foo(alpha => 1, beta => 1, gamma => 1) }, "incorrect params, too many");

@pvd = two_of('alpha', one_of(qw(beta gamma)));

ok(foo(alpha => 1, beta => 1) eq 'woot', "correct params, code-ref");
ok(foo(alpha => 1, gamma => 1) eq 'woot', "correct params, code-ref");
dies_ok(sub { foo(gamma => 1, beta => 1) }, "incorrect params, fails scalar");
dies_ok(sub { foo(alpha => 1) }, "incorrect params, not enough");
dies_ok(sub { foo(alpha => 1, beta => 1, gamma => 1) }, "incorrect params, fails code-ref");

is(
  Params::Validate::Dependencies::document(@pvd),
  "two of ('alpha' or one of ('beta' or 'gamma'))",
  'auto-doc does tree jibber-jabber'
);
is(
  Params::Validate::Dependencies::document(one_of('foo', two_of(qw(bar baz barf)))),
  "one of ('foo' or two of ('bar', 'baz' or 'barf'))",
  "auto-doc does tree jibber-jabber t'other way round too"
);

SKIP: {
    skip "only on perl 5.18 and higher" if($] <= 5.018);
    eval 'use Data::Domain::Dependencies qw(Dependencies)';
my $domain = Dependencies(@pvd);
    ok(!$domain->inspect({alpha => 1, gamma => 1}), "DDD: correct params");
    ok($domain->inspect({alpha => 1, beta => 1, gamma => 1}), "DDD: incorrect params");
}

sub foo {
  validate(@_, @pvd);
  return 'woot';
}
