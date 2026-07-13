#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing is like subtest warning warnings );
use feature      qw( signatures );
use experimental qw( signatures );

use lib                       qw( lib t/lib );
use FakePolicy                ();
use Perl::Critic::PJCJ::Fixer ();
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting qw(
  desc_double
  desc_optimal
  desc_remove_parens
  desc_single
  desc_use_qw
);

sub fixer ($flags, $description) {
  my $fixer = Perl::Critic::PJCJ::Fixer->new;
  $fixer->{policy}
    = FakePolicy->new(flags => $flags, description => $description);
  $fixer
}

subtest "Class and explanation pairs the policy cannot produce" => sub {
  my @cases = (
    ["PPI::Token::Quote::Single",      desc_single,        q(my $x = 'a';)],
    ["PPI::Token::Quote::Double",      desc_double,        'my $x = "a";'],
    ["PPI::Token::Quote::Literal",     desc_remove_parens, 'my $x = q(a);'],
    ["PPI::Token::Quote::Interpolate", desc_remove_parens, 'my $x = qq(a);'],
    ["PPI::Token::QuoteLike::Words",   desc_single,        'my @w = qw( a );'],
  );
  for my $case (@cases) {
    my ($class, $expl, $code) = @$case;
    is fixer($class, $expl)->fix($code), $code, "$class with $expl declines";
  }
};

subtest "Unmapped descriptions warn" => sub {
  my $out;
  like warning {
    $out = fixer("PPI::Statement::Include", "use say")->fix('use Foo "a";')
  }, qr/no fix mapping for 'use say' at line 1/,
    "an unmapped description warns";
  is $out, 'use Foo "a";', "and the source is unchanged";

  my @w = warnings {
    fixer("PPI::Token::Quote::Single", "use say")
      ->fix(q(my $x = 'a'; my $y = 'b';))
  };
  is @w, 1, "the same unmapped description warns only once";
};

subtest "Include descriptions without matching structure" => sub {
  is fixer("PPI::Statement::Include", desc_single)->fix('use Foo "a";'),
    'use Foo "a";', "a non-operator include explanation declines";
  is fixer("PPI::Statement::Include", desc_optimal("q()"))
    ->fix('use Foo "a";'), 'use Foo "a";',
    "a non-qw operator include explanation declines";
  is fixer("PPI::Statement::Include", desc_use_qw)->fix("use Foo;"),
    "use Foo;", "a use statement without arguments declines";
  is fixer("PPI::Statement::Include", desc_use_qw)->fix("use"), "use",
    "a degenerate use statement passes through the fixer";
  is fixer("PPI::Statement::Include", desc_remove_parens)->fix("use Foo;"),
    "use Foo;", "a use statement without parentheses declines";
  is fixer("PPI::Statement::Include", desc_remove_parens)->fix("use Foo ();"),
    "use Foo;", "empty parentheses are removed with their leading space";
  is fixer("PPI::Statement::Include", desc_remove_parens)->fix("use Foo();"),
    "use Foo;", "empty parentheses without a leading space are removed";
};

subtest "Replacements which do not preserve the value are declined" => sub {
  is fixer("PPI::Token::Quote::Single", desc_use_qw)->fix(q(my $x = ' ';)),
    q(my $x = ' ';), "a space cannot survive as a qw word";
};

subtest "Quote-sensitive escapes decline single-quote conversion" => sub {
  my $double = 'my $x = "\$a\FBAR";';
  is fixer("PPI::Token::Quote::Double", desc_single)->fix($double), $double,
    "a double-quoted string with \\F is not rewritten to single quotes";

  my $interp = 'my $x = qq(\$a\FBAR);';
  is fixer("PPI::Token::Quote::Interpolate", desc_single)->fix($interp),
    $interp, "a qq string with \\F is not rewritten to single quotes";

  my $plain = 'my $x = "\$aBAR";';
  is fixer("PPI::Token::Quote::Double", desc_single)->fix($plain),
    q(my $x = '$aBAR';), "escape-free content still converts to single quotes";
};

subtest "Interpolation-changing command fixes are declined" => sub {
  my $qx_single = q(my $out = qx'echo $$';);
  is fixer("PPI::Token::QuoteLike::Command", desc_optimal("qx()"))
    ->fix($qx_single), $qx_single, "qx'' keeps its non-interpolating delimiter";

  is fixer("PPI::Token::QuoteLike::Command", desc_optimal("qx()"))
    ->fix('my $out = qx"echo $$";'), 'my $out = qx(echo $$);',
    "interpolating qx is still re-delimited";

  is fixer("PPI::Token::Quote::Single", desc_optimal("qx()"))
    ->fix(q(my $x = 'a';)), q(my $x = 'a';),
    "a plain string does not become an interpolating command";
};

done_testing
