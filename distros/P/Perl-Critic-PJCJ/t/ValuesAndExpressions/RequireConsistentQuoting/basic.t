#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing is like ok subtest );
use feature      qw( signatures );
use experimental qw( signatures );

# Test the policy directly without using Perl::Critic framework
use lib qw( lib t/lib );
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting ();
use ViolationFinder qw( bad count_violations good );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "Policy methods" => sub {
  my @themes = $Policy->default_themes;
  is @themes,    1,          "default_themes returns one theme";
  is $themes[0], "cosmetic", "default theme is cosmetic";

  my @types = $Policy->applies_to;
  is @types, 7, "applies_to returns 7 token types";
  like $types[0], qr/Quote/, "applies_to returns quote token types";

  is $Policy->delimiter_preference_order("("), 0, "() has preference 0";
  is $Policy->delimiter_preference_order("["), 1, "[] has preference 1";
  is $Policy->delimiter_preference_order("<"), 2, "<> has preference 2";
  is $Policy->delimiter_preference_order("{"), 3, "{} has preference 3";
  is $Policy->delimiter_preference_order("x"), 99,
    "invalid delimiter returns 99";
  ok !$Policy->would_interpolate("simple"),
    "Simple string doesn't interpolate";
  ok $Policy->would_interpolate('$var'),   "Variable interpolates";
  ok $Policy->would_interpolate('@array'), "Array interpolates";
  ok !$Policy->would_interpolate('\\$escaped'),
    "Escaped variable doesn't interpolate";
};

subtest "Basic functionality" => sub {
  bad $Policy, q(my $x = 'hello'), 'use ""',
    "Single quoted simple string should use double quotes";
  good $Policy, 'my $x = "hello"', "Double quoted simple string";

  # Multiple violations
  count_violations $Policy, q(
    my $x = 'hello';
    my $y = 'world';
    my $z = 'foo';
  ), 3, "Multiple simple single-quoted strings all violate";

  # Mixed violations
  count_violations $Policy, q(
    my $x = 'hello';
    my $y = "world";
    my $z = 'user@example.com';
  ), 1, "Only simple single-quoted string violates";
};

subtest "Invalid token types" => sub {
  # Test that non-quote tokens don't violate
  my $doc = PPI::Document->new(\'my $x = 42');
  $doc->find(
    sub ($top, $elem) {
      if ($elem->isa("PPI::Token::Number")) {
        # This should return undef from _parse_quote_token
        my $violation = $Policy->violates($elem, $doc);
        is $violation, undef, "Non-quote tokens don't violate";
      }
      0
    }
  );
};

subtest "Use statement argument rules" => sub {
  # Module with no arguments - OK
  good $Policy, "use Foo",    "use with no arguments is fine";
  good $Policy, "use Foo ()", "use with empty parens is fine";

  # Module with one argument - can use "" or qw()
  good $Policy, 'use Foo "arg1"',
    "use with one double-quoted argument is fine";
  bad $Policy, "use Foo 'arg1'", "use qw()",
    "use with one single-quoted argument should use qw()";
  good $Policy, "use Foo qw(arg1)", "use with one qw() argument is fine";

  # Module with multiple arguments - must use qw()
  bad $Policy, 'use Foo "arg1", "arg2"', "use qw()",
    "use with multiple quoted arguments should use qw()";
  bad $Policy, "use Foo 'arg1', 'arg2'", "use qw()",
    "use with multiple single-quoted arguments should use qw()";
  bad $Policy, "use Foo ('arg1', 'arg2')", "use qw()",
    "use with multiple arguments in parens should use qw()";
  bad $Policy, 'use Foo "arg1", "arg2", "arg3"', "use qw()",
    "use with three quoted arguments should use qw()";

  # Mixed arguments - should use qw()
  bad $Policy, "use Foo qw(arg1), 'arg2'", "use qw()",
    "mixed qw() and quotes should use qw() for all";
  bad $Policy, "use Foo 'arg1', qw(arg2)", "use qw()",
    "mixed quotes and qw() should use qw() for all";

  # Good cases with multiple arguments
  good $Policy, "use Foo qw(arg1 arg2)",
    "multiple arguments with qw() is correct";
  good $Policy, "use Foo qw(arg1 arg2 arg3)",
    "three arguments with qw() is correct";
  bad $Policy, "use Foo qw[arg1 arg2]", "use qw()",
    "qw[] should use qw() with parentheses only";

  # Other statement types should not be checked
  good $Policy, "require Foo", "require statements are not checked";
  good $Policy, "no warnings", "no statements are not checked";
};

subtest "Find optimal delimiter coverage" => sub {
  # Test find_optimal_delimiter with non-bracket current delimiter
  # This covers the condition where current delimiter is not in bracket list
  my ($optimal, $is_optimal)
    = $Policy->find_optimal_delimiter("content", "qw", "/", "/");
  is $is_optimal, 0, "Non-bracket delimiter is never optimal";

  # Test conditions with bracket vs non-bracket delimiters
  my ($optimal2, $is_optimal2)
    = $Policy->find_optimal_delimiter("content", "qw", "(", ")");
  is $is_optimal2, 1, "Bracket delimiter can be optimal";
};

done_testing;
