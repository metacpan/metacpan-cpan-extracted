#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing is ok subtest );
use feature      qw( signatures );
use experimental qw( signatures );

# Test the policy directly without using Perl::Critic framework
use lib qw( lib t/lib );
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting qw(
  desc_double
  desc_optimal
  desc_remove_parens
  desc_single
  desc_use_qw
);
use ViolationFinder qw( find_violations );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "Plain quote explanations" => sub {
  is $Policy->fix_data(desc_double), { type => "double" },
    'use "" maps to double';
  is $Policy->fix_data(desc_single), { type => "single" },
    "use '' maps to single";
};

subtest "Use statement explanations" => sub {
  is $Policy->fix_data(desc_remove_parens), { type => "remove_parens" },
    "remove parentheses maps to remove_parens";
};

subtest "Operator explanations" => sub {
  is $Policy->fix_data(desc_use_qw),
    { type => "operator", op => "qw", start => "(", end => ")" },
    "use qw() carries operator and delimiters";
  is $Policy->fix_data(desc_optimal("q[]")),
    { type => "operator", op => "q", start => "[", end => "]" },
    "use q[] carries operator and delimiters";
  is $Policy->fix_data(desc_optimal("qq<>")),
    { type => "operator", op => "qq", start => "<", end => ">" },
    "use qq<> carries operator and delimiters";
  is $Policy->fix_data(desc_optimal("qx{}")),
    { type => "operator", op => "qx", start => "{", end => "}" },
    "use qx{} carries operator and delimiters";
};

subtest "Unknown explanations" => sub {
  is $Policy->fix_data("use say"), undef,
    "an unknown explanation returns undef";
};

my @Snippets = (
  q(my $x = 'hello'),
  'my $output = "Price: \$10"',
  'my @x = qw{simple words}',
  'my @x = qw(word(with)parens)',
  'my $x = qq(simple)',
  'use Foo "a1", "a2";',
  'use Qux ( key => "value" );',
);

sub emitted_violations () {
  map find_violations($Policy, $_), @Snippets
}

subtest "Every emitted description has fix data" => sub {
  for my $violation (emitted_violations) {
    my $desc = $violation->description;
    ok $Policy->fix_data($desc), "fix data exists for $desc";
  }
};

subtest "Violations carry their fix structure" => sub {
  for my $violation (emitted_violations) {
    ok $violation->can("fix"), "violation has a fix method";
    is $violation->fix, $Policy->fix_data($violation->description),
      "attached fix matches the rendered lookup";
  }
};

done_testing;
