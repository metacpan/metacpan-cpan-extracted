#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing subtest );
use feature      qw( signatures );
use experimental qw( signatures );

# Test that unterminated quote tokens are left alone
use lib qw( lib t/lib );
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting
  qw( desc_double desc_use_qw );
use ViolationFinder qw( bad good );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "Unterminated quote tokens are not flagged" => sub {
  good $Policy, q(my $x = 'ab),      "unterminated single quote";
  good $Policy, 'my $x = "ab',       "unterminated double quote";
  good $Policy, 'my @w = qw( a b',   "unterminated qw";
  good $Policy, 'my $t = qq(ab',     "unterminated qq";
  good $Policy, 'my $x = q(ab',      "unterminated q";
  good $Policy, "use Foo 'a', 'bcd", "unterminated string in use";
};

subtest "Complete final tokens are still flagged" => sub {
  # No trailing newline or semicolon: the quote is the final token, so
  # these exercise the reparse probe's complete path
  bad $Policy, q(my $x = 'ab'), desc_double,
    "terminated single quote at end of file";
  bad $Policy, 'my @w = qw/ a b /', desc_use_qw,
    "terminated qw at end of file";
};

done_testing;
