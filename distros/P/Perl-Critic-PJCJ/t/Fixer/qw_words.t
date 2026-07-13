#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing is ok subtest );
use feature      qw( signatures );
use experimental qw( signatures );

use lib                       qw( lib t/lib );
use PPI                       ();
use Perl::Critic::PJCJ::Fixer ();
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting ();

my $Fixer = Perl::Critic::PJCJ::Fixer->new;
my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

sub qw_token ($code) {
  my $doc = PPI::Document->new(\$code);
  my ($token) = @{ $doc->find("PPI::Token::QuoteLike::Words") || [] };
  ($doc, $token)
}

subtest "qw words unescape backslashes as perl does" => sub {
  my $code = <<'CODE';
my @w = qw( a\\b c );
CODE
  my ($doc, $qw) = qw_token($code);
  is $Fixer->_normalised_value($qw), join("\0", "a\\b", "c"),
    "_normalised_value collapses escaped backslashes";
  my @words;
  ok $Policy->collect_qw_words(\@words, $qw), "words are collected";
  is \@words, ["a\\b", "c"], "collect_qw_words collapses escaped backslashes";
};

subtest "backslash qw content is re-delimited unchanged" => sub {
  my $in = <<'CODE';
my @w = qw[ a\\b c ];
CODE
  my $out = <<'CODE';
my @w = qw( a\\b c );
CODE
  is $Fixer->fix($in), $out, "re-delimiting preserves the raw words";
};

subtest "backslash words still decline the use rewrite" => sub {
  my $in = <<'CODE';
use Foo qw( a\\b ), "c";
CODE
  is $Fixer->fix($in), $in, "backslash word fails the qw word filter";
};

done_testing;
