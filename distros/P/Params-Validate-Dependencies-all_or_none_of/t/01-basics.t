use strict;
use warnings;

use Params::Validate::Dependencies qw(:all);
use Params::Validate::Dependencies::all_or_none_of;

use Test::More tests => 15;

my @pvd = all_or_none_of(qw(alpha beta gamma));

foreach my $one (qw(alpha beta gamma)) {
  my @two = grep { $_ ne $one } qw(alpha beta gamma);
  dies_ok(sub { foo($one => 1) }, "only one ($one) of three, validation failed");
  dies_ok(sub { foo($two[0] => 1, $two[1] => 1) },
    "only two (".join(', ', @two).") of three, validation failed");
}

ok(foo(), "none, validation succeeded");
ok(foo(map { $_ => 1 } qw(alpha beta gamma)), "all three, validation succeeded");

@pvd = all_or_none_of('alpha', any_of(qw(beta gamma)));
dies_ok(sub { foo(alpha => 1) }, "validation fails (alpha only), code-ref");
dies_ok(sub { foo(beta  => 1) }, "validation fails (beta  only), code-ref");
dies_ok(sub { foo(gamma => 1) }, "validation fails (gamma only), code-ref");
ok(foo(alpha => 1, beta  => 1), "validation succeeds (alpha, beta), code-ref");
ok(foo(alpha => 1, gamma => 1), "validation succeeds (alpha, gamma), code-ref");
ok(foo(), "validation succeeds ([nothing]), code-ref");

is(
  Params::Validate::Dependencies::document(@pvd),
  "all or none of ('alpha' and any of ('beta' or 'gamma'))",
  "doco works"
);

sub dies_ok {
  my($sub, $look_for, $text) = @_;
  ($look_for, $text) = ('^', $look_for) if(!defined($text));

  eval { $sub->() };
  ok($@ && $@ =~ /$look_for/i, $text);
}

sub foo {
  validate(@_, @pvd);
  return 'woot';
}
