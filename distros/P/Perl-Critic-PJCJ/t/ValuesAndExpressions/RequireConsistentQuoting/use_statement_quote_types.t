#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing subtest );
use feature      qw( signatures );
use experimental qw( signatures );

# Test to exercise uncovered branches in quote checking within use statements
use lib qw( lib t/lib );
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting ();
use ViolationFinder qw( bad good );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "Exercise _is_in_use_statement branches" => sub {
  # These test cases are designed to exercise the _is_in_use_statement method
  # by having quote tokens inside use statements that would normally be flagged

  # Test q() quotes inside use statements - should be skipped by regular q()
  # checking
  good $Policy, "use Foo q(simple)",
    "q() in use statements bypasses regular q() rules";
  good $Policy, "use Foo q{simple}",
    "q{} in use statements bypasses regular q() rules";
  good $Policy, "use Foo q[simple]",
    "q[] in use statements bypasses regular q() rules";
  good $Policy, "use Foo q<simple>",
    "q<> in use statements bypasses regular q() rules";

  # Test qq() quotes inside use statements - should be skipped by regular qq()
  # checking
  good $Policy, "use Foo qq(simple)",
    "qq() in use statements bypasses regular qq() rules";
  good $Policy, "use Foo qq{simple}",
    "qq{} in use statements bypasses regular qq() rules";
  good $Policy, "use Foo qq[simple]",
    "qq[] in use statements bypasses regular qq() rules";
  good $Policy, "use Foo qq<simple>",
    "qq<> in use statements bypasses regular qq() rules";
};

subtest "Use statements with multiple quote types" => sub {
  # Test multiple arguments to trigger the use statement multiple argument rule
  bad $Policy, "use Foo q(arg1), q(arg2)", "use qw()",
    "multiple q() arguments trigger use statement rule";
  bad $Policy, "use Foo qq(arg1), qq(arg2)", "use qw()",
    "multiple qq() arguments trigger use statement rule";

  # Mixed quote types
  bad $Policy, 'use Foo q(arg1), "arg2"', "use qw()",
    "mixed q() and double quotes trigger use statement rule";
  bad $Policy, 'use Foo qq(arg1), "arg2"', "use qw()",
    "mixed qq() and single quotes trigger use statement rule";
};

subtest "Edge cases for coverage" => sub {
  # Test semicolon handling - covers the semicolon branch in
  # _extract_use_arguments
  good $Policy, 'use Foo "arg"; # with semicolon',
    "use statement with semicolon works";

  # Test require and no statements to ensure they don't trigger use statement
  # logic
  bad $Policy, "require q(file.pl)", 'use ""',
    "require with q() is not processed by use statement logic";
  bad $Policy, "no warnings qq(experimental)", 'use ""',
    "no statement qq() is processed by regular quote logic";
};

subtest "Use statement structure parsing coverage" => sub {
  # Test to hit the semicolon condition (line 373)
  # $child->isa("PPI::Token::Structure") and $child->content eq ";"
  bad $Policy, 'use Foo "arg1", "arg2";', "use qw()",
    "use statement with semicolon and multiple args";

  # Test to hit condition line 410: $string_count > 1 and not $has_qw
  # This should be triggered by multiple string arguments without qw
  bad $Policy, 'use Foo "arg1", "arg2", "arg3"', "use qw()",
    "three string arguments without qw should violate";
};

done_testing;
