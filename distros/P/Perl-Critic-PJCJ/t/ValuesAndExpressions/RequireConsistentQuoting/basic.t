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
);
use ViolationFinder qw( bad count_violations good );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "Policy methods" => sub {
  my @themes = $Policy->default_themes;
  is @themes,    2,          "default_themes returns two themes";
  is $themes[0], "cosmetic", "first theme is cosmetic";
  is $themes[1], "pjcj",     "second theme is pjcj";

  my @types = $Policy->applies_to;
  is @types,                  7, "applies_to returns 7 token types";
  is +(grep /Quote/, @types), 6, "applies_to returns 6 quote token types";

  my $optimal = sub ($content) {
    my ($delim) = $Policy->find_optimal_delimiter($content, "qw", "(", ")");
    $delim->{start}
  };
  is $optimal->(""),        "(", "empty content prefers ()";
  is $optimal->("a(b"),     "[", "parens in content fall back to []";
  is $optimal->("a(b)[c]"), "<", "parens and brackets fall back to <>";
  is $optimal->("()[]<>"),  "{", "all lower preferences fall back to {}";
  ok !$Policy->would_interpolate("simple"),
    "Simple string doesn't interpolate";
  ok $Policy->would_interpolate('$var'),   "Variable interpolates";
  ok $Policy->would_interpolate('@array'), "Array interpolates";
  ok !$Policy->would_interpolate('\\$escaped'),
    "Escaped variable doesn't interpolate";

  ok $Policy->prepare_to_scan_document(undef),
    "prepare_to_scan_document returns true";

  my $doc  = PPI::Document->new(\"use Foo 'a', 'b';");
  my $stmt = $doc->find_first("PPI::Statement::Include");
  $stmt->remove;
  my ($str) = @{ $stmt->find("PPI::Token::Quote::Single") };
  ok !$Policy->violates($str, undef),
    "detached use-statement strings are still exempt";
};

subtest "use cache distinguishes live documents" => sub {
  # Two documents held alive at once force the cache to notice the change
  # of document by refaddr rather than only through the weak reference
  # going undef
  my $src  = "use Foo 'one', 'two';";
  my $doc1 = PPI::Document->new(\$src);
  my $doc2 = PPI::Document->new(\$src);
  my ($s1) = @{ $doc1->find("PPI::Token::Quote::Single") };
  my ($s2) = @{ $doc2->find("PPI::Token::Quote::Single") };
  ok !$Policy->violates($s1, $doc1), "first document string is exempt";
  ok !$Policy->violates($s2, $doc2), "second live document string is exempt";
};

subtest "Basic functionality" => sub {
  bad $Policy, q(my $x = 'hello'), desc_double,
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
