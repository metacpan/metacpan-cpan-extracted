#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;
use feature "signatures";
use experimental "signatures";
use lib qw( lib t/lib );

use Test2::V0 qw( done_testing subtest );

use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting qw(
  desc_optimal
  desc_single
);
use ViolationFinder qw( bad good );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "Double quoted strings" => sub {
  good $Policy, 'my $x = "hello"', "Double quoted simple string";
  good $Policy, q(my $x = "It's a nice day"),
    "String with single quote needs double quotes";
  good $Policy, 'my $x = "Hello $name"',
    "String with interpolation needs double quotes";

  good $Policy, 'my $mixed = "\$a $b"',
    "Mixed escaped and real interpolation should stay double quotes";
};

subtest "Escaped special characters" => sub {
  bad $Policy, 'my $output = "Price: \$10"', desc_single,
    "Escaped dollar signs should use single quotes";
  bad $Policy, 'my $email = "\@domain"', desc_single,
    "Escaped at-signs should use single quotes";

  # An apostrophe would need escaping in '', so prefer q() instead
  bad $Policy, q(my $x = "\$10 isn't"), desc_optimal("q()"),
    "escaped sigil with an apostrophe should use q() not single quotes";

  # POD EXAMPLES: the email example is only detectable in escaped form
  bad $Policy, 'my $email = "user\@domain.com"', desc_single,
    "escaped @ in double quotes should use single quotes";
  good $Policy, 'my $email = "user@domain.com"',
    "bare @ interpolates, so the policy accepts double quotes";
  bad $Policy, 'my $quote = "\""', desc_single,
    "Escaped double quotes should use single quotes";
  bad $Policy, 'my $csv = "val1,\"unclosed quote,val3\n"',
    desc_optimal("qq()"),
    "Escaped double quotes with escape sequences should use qq()";
};

subtest "Interpolation with quotes" => sub {
  # Strings that interpolate and have escaped quotes should use qq()
  bad $Policy, 'my $x = "$var \""', desc_optimal("qq()"),
    "Escaped double quotes with interpolation should use qq()";
  bad $Policy, 'my $text = "contains $var and \"quotes\""',
    desc_optimal("qq()"),
    "Double quotes with interpolation and escaped quotes should use qq()";
  bad $Policy, 'my $x = "string with $var and \"quotes\""',
    desc_optimal("qq()"),
    "Double quotes with interpolation and escaped quotes should use qq()";

  # Contains both single and double quotes
  good $Policy, q(my $text = "contains 'single' quotes"),
    '"" appropriate when content has single quotes';
  good $Policy, q[my $text = qq(contains 'both' and "quotes")],
    "qq() appropriate when content has both quote types";
};

subtest "Additional double quote coverage tests" => sub {
  # Test to hit the condition in double quote checking (line 292)
  # This should exercise: $would_interpolate and not $has_single_quotes
  good $Policy, 'my $x = "simple";',
    "simple double quoted string is acceptable";

  # Test interpolation cases to exercise would_interpolate branches
  good $Policy, 'my $x = "variable: $var";',
    "double quotes justified by interpolation";
  good $Policy, 'my $x = "array: @arr";',
    "double quotes justified by array interpolation";
  bad $Policy, 'my $x = "escaped: \\$var";', desc_single,
    "escaped variables suggest single quotes";
};

done_testing;
