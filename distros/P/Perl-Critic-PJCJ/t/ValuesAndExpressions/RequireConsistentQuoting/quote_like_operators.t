#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing subtest );
use feature      qw( signatures );
use experimental qw( signatures );

# Test the policy directly without using Perl::Critic framework
use lib qw( lib t/lib );
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting qw(
  desc_optimal
  desc_use_qw
);
use ViolationFinder qw( bad good );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "qw() operator" => sub {
  # Simple content should use ()
  bad $Policy, 'my @x = qw{simple words}', desc_use_qw,
    "qw{} with no delimiters should use qw()";
  bad $Policy, 'my @x = qw[simple words]', desc_use_qw,
    "qw[] with no delimiters should use qw()";
  bad $Policy, 'my @x = qw<simple words>', desc_use_qw,
    "qw<> with no delimiters should use qw()";
  good $Policy, 'my @x = qw(simple words)',
    "qw() is preferred for simple content";

  # Empty quotes should prefer ()
  bad $Policy, 'my @x = qw{}', desc_use_qw, "Empty qw{} should use qw()";
  bad $Policy, 'my @x = qw[]', desc_use_qw, "Empty qw[] should use qw()";
  good $Policy, 'my @x = qw()', "Empty qw() is preferred";

  # Non-bracket delimiters
  bad $Policy, 'my @x = qw/word word/', desc_use_qw,
    "qw// should use qw() - brackets preferred";
  bad $Policy, 'my @x = qw|word word|', desc_use_qw,
    "qw|| should use qw() - brackets preferred";
  bad $Policy, 'my @x = qw#word word#', desc_use_qw,
    "qw## should use qw() - brackets preferred";
  good $Policy, 'my @x = qw(word word)',
    "qw() uses preferred bracket delimiters";

  # With slashes and pipes
  bad $Policy, 'my @words = qw/word\/with\/slashes/', desc_use_qw,
    "qw// with slashes should use qw() to avoid escapes";
  good $Policy, 'my @words = qw(word/with/slashes)',
    "qw() optimal when words have slashes";

  bad $Policy, 'my @words = qw|word\|with\|pipes|', desc_use_qw,
    "qw|| with pipes should use qw() to avoid escapes";
  good $Policy, 'my @words = qw(word|with|pipes)',
    "qw() optimal when words have pipes";

  # Whitespace variations
  bad $Policy, 'my @x = qw  {word(with)parens}', desc_optimal("qw[]"),
    "qw with whitespace before delimiter";
  bad $Policy, "my \@x = qw\t{word(with)parens}", desc_optimal("qw[]"),
    "qw with tab before delimiter";
  bad $Policy, 'my @x = qw     <simple words>', desc_use_qw,
    "qw<> with multiple spaces should use qw()";
};

subtest "qx() operator" => sub {
  # Simple commands
  bad $Policy, 'my $output = qx[ls]', desc_optimal("qx()"),
    "qx[] for simple command should use qx()";
  bad $Policy, 'my $output = qx{ls}', desc_optimal("qx()"),
    "qx{} for simple command should use qx()";
  bad $Policy, 'my $output = qx<ls>', desc_optimal("qx()"),
    "qx<> for simple command should use qx()";
  good $Policy, 'my $output = qx(ls)',
    "qx() is preferred for simple commands";

  # Commands with special characters
  bad $Policy, 'my $output = qx/ls \/tmp/', desc_optimal("qx()"),
    "qx// with slashes should use qx() to avoid escapes";
  good $Policy, 'my $output = qx(ls /tmp)',
    "qx() optimal when content has slashes";

  bad $Policy, 'my $output = qx|echo \|pipe|', desc_optimal("qx()"),
    "qx|| with pipes should use qx() to avoid escapes";
  good $Policy, 'my $output = qx(echo |pipe)',
    "qx() optimal when content has pipes";

  # With single quotes: perlop says qx does not interpolate when its
  # delimiter is '', so that delimiter is semantic, not stylistic
  good $Policy, q(my $output = qx'echo \'hello\''),
    "qx'' suppresses interpolation so its delimiter is kept";
  good $Policy, q(my $output = qx'echo $$'),
    "qx'' with shell variables is exempt from delimiter rules";
  bad $Policy, 'my $output = qx"echo $$"', desc_optimal("qx()"),
    "interpolating qx with a non-bracket delimiter is still flagged";
  good $Policy, q[my $output = qx(echo 'hello')],
    "qx() optimal when content has single quotes";
};

done_testing;
