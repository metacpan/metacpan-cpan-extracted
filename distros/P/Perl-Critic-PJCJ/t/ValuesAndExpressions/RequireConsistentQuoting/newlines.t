#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing subtest );
use feature      qw( signatures );
use experimental qw( signatures );

# Test the newline special case handling
use lib qw( lib t/lib );
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting ();
use ViolationFinder qw( bad good );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "Single-quoted strings with newlines" => sub {
  # Single-quoted strings with literal newlines are allowed
  good $Policy, <<~'EOCODE', "single quotes with literal newline";
    my $text = 'line 1
    line 2';
    EOCODE

  good $Policy, <<~'EOCODE', "single quotes with multiple newlines";
    my $text = 'line 1
    line 2
    line 3';
    EOCODE

  # Single quotes with escaped single quotes and newlines are allowed
  good $Policy, <<~'EOCODE', "single quotes with escaped quotes and newlines";
    my $text = 'line 1 with \'quote\'
    line 2';
    EOCODE
};

subtest "Double-quoted strings with newlines" => sub {
  # Double-quoted strings with literal newlines are allowed
  good $Policy, <<~'EOCODE', "double quotes with literal newline";
    my $text = "line 1
    line 2";
    EOCODE

  good $Policy, <<~'EOCODE', "double quotes with interpolation and newlines";
    my $var = "world";
    my $text = "Hello $var
    line 2";
    EOCODE

  # Double quotes with escaped sigils and newlines are allowed
  good $Policy, <<~'EOCODE', "double quotes with escaped sigils and newlines";
    my $text = "Price: \$10
    Next line";
    EOCODE
};

subtest "q() operators with newlines" => sub {
  # q() with newlines is allowed regardless of content
  good $Policy, <<~'EOCODE', "q() with newlines";
    my $text = q(line 1
    line 2);
    EOCODE

  good $Policy, <<~'EOCODE', "q[] with newlines and quotes";
    my $text = q[line 1 with 'quotes'
    line 2];
    EOCODE

  good $Policy, <<~'EOCODE', "q{} with newlines and complex content";
    my $text = q{line 1 with 'single' and "double" quotes
    line 2};
    EOCODE
};

subtest "qq() operators with newlines" => sub {
  # qq() with newlines is allowed
  good $Policy, <<~'EOCODE', "qq() with newlines";
    my $text = qq(line 1
    line 2);
    EOCODE

  good $Policy, <<~'EOCODE', "qq() with interpolation and newlines";
    my $var = "world";
    my $text = qq(Hello $var
    line 2);
    EOCODE

  good $Policy, <<~'EOCODE', "qq[] with newlines and parentheses";
    my $text = qq[line 1 (with parens)
    line 2];
    EOCODE

  # Common multi-line use case from documentation
  good $Policy, <<~'EOCODE', "qq() with indented multi-line content";
    my $text = qq(
      line 1
      line 2
    );
    EOCODE
};

subtest "Strings without newlines still follow rules" => sub {
  # Single quotes without newlines should still be checked
  bad $Policy, <<~'EOCODE', 'use ""', "single quotes without newlines";
    my $text = 'hello';
    EOCODE

  # qq() without newlines for simple strings should still be checked
  bad $Policy,
    <<~'EOCODE', 'use ""', "qq() without newlines for simple string";
    my $text = qq(hello);
    EOCODE
};

subtest "Edge cases" => sub {
  # Escape sequence \n in single quotes is preserved
  # (has dangerous escape sequences)
  good $Policy, <<~'EOCODE', "\\n in single quotes preserved";
    my $text = 'hello\nworld';
    EOCODE

  # Mixed content: literal newline and escape sequence
  good $Policy, <<~'EOCODE', "literal newline with \\n escape";
    my $text = "hello\n
    world";
    EOCODE

  # Empty string with just newlines
  good $Policy, <<~'EOCODE', "string with only newlines";
    my $text = '

    ';
    EOCODE

  # String without escape sequences or newlines should still be checked
  bad $Policy, <<~'EOCODE', 'use ""', "simple string without newlines";
    my $text = 'hello world';
    EOCODE
};

done_testing;
