use strict;
use warnings;

use Params::Validate::Dependencies qw(:all);

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

dies_ok(sub { Params::Validate::Dependencies::document(@pvd) },
  'auto-doc detects un-doccable stuff OK');
is(
  Params::Validate::Dependencies::document(one_of('foo', two_of('bar'))),
  "one of ('foo' or [coderef does not support autodoc])",
  'auto-doc detects un-doccable stuff deep down in the tree'
);

SKIP: {
    skip "only on perl 5.18 and higher" if($] <= 5.018);
    eval 'use Data::Domain::Dependencies qw(Dependencies)';

    my $domain = Dependencies(@pvd);
    ok(!$domain->inspect({alpha => 1, gamma => 1}), "DDD: correct params");
    ok($domain->inspect({alpha => 1, beta => 1, gamma => 1}), "DDD: incorrect params");
    
    dies_ok(sub { $domain->generate_documentation() },
      "DDD: can't document the undoccable");
    is(
      Dependencies(one_of('foo', two_of('bar')))->generate_documentation(),
      "one of ('foo' or [coderef does not support autodoc])",
      'DDD auto-doc also detects un-doccable stuff deep down in the tree'
    );
}

sub two_of {
  my @options = @_;
  return sub {
    my $hashref = shift;
    my $count = 0;
    foreach my $option (@options) {
      $count++ if(
        (!ref($option) && exists($hashref->{$option})) ||
        (ref($option) && $option->($hashref))
      );
    }
    return ($count == 2);
  }
}

sub foo {
  validate(@_, @pvd);
  return 'woot';
}
