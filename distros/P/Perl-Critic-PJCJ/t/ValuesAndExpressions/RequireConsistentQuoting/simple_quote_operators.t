#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing subtest );
use feature      qw( signatures );
use experimental qw( signatures );

# Test that q() and qq() suggest simpler quotes for simple strings
use lib qw( lib t/lib );
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting ();
use ViolationFinder qw( bad good );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "q() with simple strings - follow single quote rules" => sub {
  # Case 1: Simple strings that would cause single quotes to suggest double
  # quotes
  bad $Policy, 'my $x = q(simple);', 'use ""',
    "q() with simple string should suggest double quotes";
  bad $Policy, 'my $x = q{simple};', 'use ""',
    "q{} with simple string should suggest double quotes";

  # Case 2: Strings where single quotes would be acceptable
  bad $Policy, 'my $x = q(has "quotes");', "use ''",
    "q() with content that justifies single quotes should suggest them";
  bad $Policy, 'my $x = q{$variable};', "use ''",
    "q{} with variable content should suggest single quotes";

  # Case 3: Strings that would cause single quotes to suggest double quotes
  # (because they contain single quotes but no variables)
  bad $Policy, q[my $x = q(don't);], 'use ""',
    "q() with embedded single quote should suggest double quotes";
  bad $Policy, q(my $x = q{user's};), 'use ""',
    "q{} with embedded single quote should suggest double quotes";

  # Case 3: Strings that would cause single quotes to need q()
  # (because they have both single and double quotes)
  bad $Policy, q(my $x = q/mix 'single' and "double"/;), "use q()",
    "q/ with mixed quotes should suggest q()";
  bad $Policy, q(my $x = q|mix 'single' and "double"|;), "use q()",
    "q| with mixed quotes should suggest q()";

  # Case 4: Strings that have single quotes that would need escaping
  bad $Policy, q(my $x = q/can't and won't/;), 'use ""',
    "q/ with single quotes should suggest double quotes";
};

subtest "qq() with simple strings - follow double quote rules" => sub {
  # Case 1: Simple strings that would be fine as double quotes
  bad $Policy, 'my $x = qq(simple);', 'use ""',
    "qq() with simple string should suggest double quotes";
  bad $Policy, 'my $x = qq{simple};', 'use ""',
    "qq{} with simple string should suggest double quotes";

  # Case 2: Strings that would cause double quotes to suggest single quotes
  # (because they have escaped characters that look like variables)
  bad $Policy, 'my $x = qq(price: \\$5.00);', "use ''",
    "qq() with escaped dollar should suggest single quotes";
  bad $Policy, 'my $x = qq{email\\@domain.com};', "use ''",
    "qq{} with escaped at-sign should suggest single quotes";

  # Case 3: Strings that would cause double quotes to need qq()
  # (because they contain double quotes and need interpolation)
  bad $Policy, 'my $var = "test"; my $x = qq/has "quotes" and $var/;',
    "use qq()", "qq/ with quotes and interpolation should suggest qq()";
  bad $Policy, 'my @arr = (); my $x = qq|has "quotes" and @arr|;',
    "use qq()", "qq| with quotes and interpolation should suggest qq()";
};

subtest "Consistency verification" => sub {
  # Verify that following the suggestion doesn't create new violations

  # These simple cases should not violate when changed to suggested form
  good $Policy, 'my $x = "simple";',
    "suggested form for q(simple) should not violate";
  good $Policy, 'my $x = "simple";',
    "suggested form for qq(simple) should not violate";

  # These should not violate when changed to suggested form
  good $Policy, q(my $x = 'has "quotes"';),
    'suggested form for q(has "quotes") should not violate';
  good $Policy, q(my $x = "don't";),
    "suggested form for q(don't) should not violate";
  good $Policy, q(my $x = 'price: $5.00';),
    'suggested form for qq(price: \\$5.00) should not violate';

  # These complex cases should not violate when using q()/qq() with optimal
  # delimiters
  good $Policy, q[my $x = q(mix 'single' and "double");],
    "q() with optimal delimiter should not violate";
  good $Policy, 'my $var = "test"; my $x = qq(has "quotes" and $var);',
    "qq() with optimal delimiter should not violate";
};

done_testing;
