#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing is like subtest );
use feature      qw( signatures );
use experimental qw( signatures );

# Test the policy directly without using Perl::Critic framework
use lib                                                 qw( lib t/lib );
use Perl::Critic::Policy::CodeLayout::ProhibitLongLines ();
use ViolationFinder qw( bad count_violations good );

my $Policy = Perl::Critic::Policy::CodeLayout::ProhibitLongLines->new;

subtest "Policy methods" => sub {
  # Test default_themes
  my @themes = $Policy->default_themes;
  is @themes,    2,            "default_themes returns two themes";
  is $themes[0], "cosmetic",   "first theme is cosmetic";
  is $themes[1], "formatting", "second theme is formatting";

  # Test applies_to
  my @types = $Policy->applies_to;
  is @types,    1,               "applies_to returns one type";
  is $types[0], "PPI::Document", "applies_to returns PPI::Document";

  # Test default configuration
  is $Policy->{_max_line_length}, 80, "default max_line_length is 80";
};

subtest "Basic functionality" => sub {
  # Test lines within limit
  good $Policy, 'my $x = "hello"', "Short line within 80 chars";
  good $Policy, 'my $short = 1',   "Very short line";
  good $Policy, "",                "Empty string";
  good $Policy, "\n",              "Just newline";

  # Test lines exactly at limit (80 chars)
  my $exactly_80 = 'my $var = "' . ("x" x 67) . '";';
  is length($exactly_80), 80, "Test string is exactly 80 chars";
  good $Policy, $exactly_80, "Line exactly at 80 characters";

  # Test lines over limit
  my $over_80 = 'my $var = "' . ("x" x 68) . '";';
  is length($over_80), 81, "Test string is 81 chars";
  bad $Policy, $over_80, "Line is 81 characters long (exceeds 80)",
    "Line over 80 characters should violate";
};

subtest "Multiple lines" => sub {
  # Multiple short lines - all good
  good $Policy, qq(my \$x = "hello";\nmy \$y = "world";),
    "Multiple short lines";

  # Multiple long lines - all bad
  my $long_line1 = 'my $very_long_variable_name = '
    . '"this is a very long string that exceeds eighty chars";';
  my $long_line2 = 'my $another_long_variable = '
    . '"this is another very long string that also exceeds eighty chars";';
  my $code = $long_line1 . "\n" . $long_line2;

  my @violations = count_violations $Policy, $code, 2,
    "Multiple long lines both violate";

  # Check each violation message
  like $violations[0]->description,
    qr/Line is \d+ characters long \(exceeds 80\)/,
    "First violation has correct message";
  like $violations[1]->description,
    qr/Line is \d+ characters long \(exceeds 80\)/,
    "Second violation has correct message";

  # Mixed lines - only long ones violate
  my $mixed
    = 'my $short = 1;' . "\n"
    . 'my $very_long_variable_name = '
    . '"this is a very long string that exceeds eighty chars";' . "\n"
    . 'my $also_short = 2;';
  my @mixed_violations = count_violations $Policy, $mixed, 1,
    "Only long line in mixed content violates";
  like $mixed_violations[0]->description,
    qr/Line is \d+ characters long \(exceeds 80\)/,
    "Mixed content violation has correct message";
};

subtest "Edge cases" => sub {
  # Empty file
  good $Policy, "", "Empty file";

  # Just whitespace
  good $Policy, "   ",  "Whitespace only";
  good $Policy, "\t\t", "Tabs only";

  # Very long line
  my $very_long = 'my $x = ' . ('"' . ("a" x 200) . '"') . ";";
  bad $Policy, $very_long, "Line is 211 characters long (exceeds 80)",
    "Very long line (200+ chars) violates";

  # Line with exactly 81 characters (one over limit)
  my $line_81 = "a" x 81;
  is length($line_81), 81, "Test string is exactly 81 chars";
  bad $Policy, $line_81, "Line is 81 characters long (exceeds 80)",
    "Line with exactly 81 characters violates";
};

subtest "Configuration parameter handling" => sub {
  # Test supported_parameters method
  my @params = $Policy->supported_parameters;
  is @params, 1, "One supported parameter";

  my $param = $params[0];
  is $param->{name}, "max_line_length",    "Parameter name is max_line_length";
  is $param->{default_string},  "80",      "Default value is 80";
  is $param->{behavior},        "integer", "Parameter type is integer";
  is $param->{integer_minimum}, 1,         "Minimum value is 1";
};

done_testing;
