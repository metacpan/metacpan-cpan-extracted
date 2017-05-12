use strict;
use warnings;

use Params::Validate::Dependencies qw(:all);

use Test::More;
use Test::Exception;
END { done_testing(); }

my %pv = (
  alpha => { type => SCALAR,  optional => 1 },
  beta  => { type => SCALAR,  optional => 1 },
  gamma => { type => SCALAR,  optional => 1 },
  delta => { type => HASHREF, optional => 1 },
  bar   => { type => SCALAR,  optional => 1 },
  baz   => { type => SCALAR,  optional => 1 },
);

ok(foo(delta => { type => SCALAR, optional => 1 }),
  "good params, no deps, last param looks like a P::V spec");
ok(foo() eq 'woot', "no params, no dependencies");
dies_ok(sub { foo(alpha => []) }, "bad params, no dependencies, P::V wrapped OK");
dies_ok(sub { any_of([]) }, '*_of only take scalars and code-refs');

my @pvd = 
  any_of(
    all_of(qw(bar baz)),
    qw(alpha beta gamma),
  );

ok(foo(alpha => 1, delta => { type => SCALAR, optional => 1 }),
  "good params, deps, last param looks like a P::V spec");

{
  my %pv = ();
  ok(foo(alpha => 1, delta => { type => SCALAR, optional => 1 }),
    "deps only, last param looks like a P::V spec");
}
dies_ok(sub { foo() }, "bad params, any_of fails");
dies_ok(sub { foo(bar => 1) }, "bad params, all_of fails");
dies_ok(sub { foo(bar => 1, baz => []) },
  "bad params detected even if any_of(all_of()) passes");
like($@, qr/baz.*scalar/, "... and it died with a sensible message");
ok(foo(bar => 1, baz => 1), "good params, any_of(all_of()) matches");
ok(foo(alpha => 1, bar => 1), "any_of passes even if an all_of in it fails");

push @pvd, sub { die };
dies_ok(sub { foo(alpha => 1, bar => 1) },
  "yes, we execute multiple code-refs");

@pvd = one_of(qw(alpha beta gamma), all_of(qw(bar baz)));
ok(foo(alpha => 1), 'good params, one_of matches');
ok(foo(bar => 1, baz => 1), 'good params, one_of matches embedded code-ref');
dies_ok(sub { foo(alpha => 1, beta => 1) }, 'bad params, one_of fails');
dies_ok(sub { foo(bar => 1) }, 'bad params, one_of fails embedded code-ref');
dies_ok(sub { foo(bar => 1,baz => 1, alpha => 1) }, 'bad params, one_of fails when embedded code-ref passes');

@pvd = all_of('alpha', none_of(qw(bar baz), any_of(qw(beta))));
ok(foo(alpha => 1), 'good params, none_of matches');
dies_ok(sub { foo(alpha => 1, bar => 1) }, 'bad params, none_of fails');
dies_ok(sub { foo(alpha => 1, beta => 1) }, 'bad params, none_of fails embedded code-ref');

sub foo {
  validate(@_, \%pv, @pvd);
  return 'woot';
}
