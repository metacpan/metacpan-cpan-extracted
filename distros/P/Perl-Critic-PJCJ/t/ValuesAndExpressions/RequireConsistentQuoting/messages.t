#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing is like subtest );
use feature      qw( signatures );
use experimental qw( signatures );

# Test the policy directly without using Perl::Critic framework
use lib qw( lib t/lib );
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting qw(
  desc_double
  desc_optimal
  desc_remove_parens
  desc_single
  desc_use_qw
);
use ViolationFinder qw( bad find_violations );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "Message field placement" => sub {
  my ($v) = find_violations($Policy, q(my $x = 'hello'));
  is $v->description, desc_double, "description carries the suggestion";
  like $v->explanation, qr/consistent/,
    "explanation carries the static rationale";
};

subtest "Canonical suggestion wording" => sub {
  is desc_double,          'use ""',             "double wording";
  is desc_single,          "use ''",             "single wording";
  is desc_use_qw,          "use qw()",           "qw wording";
  is desc_remove_parens,   "remove parentheses", "remove parens wording";
  is desc_optimal("qq[]"), "use qq[]",           "optimal wording";
};

subtest "Single quote violation messages" => sub {
  bad $Policy, q(my $x = 'hello'), desc_double, "Simple single-quoted string";

  bad $Policy, q(my $x = 'I\'m happy'), desc_double,
    "Single quotes with escaped apostrophe";
};

subtest "Double quote violation messages" => sub {
  bad $Policy, 'my $output = "Price: \$10"', desc_single,
    "Double quotes with escaped dollar";
};

subtest "q() operator violation messages" => sub {
  bad $Policy, 'my $x = q(simple)', desc_double, "q() with simple content";

  bad $Policy, 'my $x = q(literal$x)', desc_single, "q() with literal dollar";
};

subtest "qq() operator violation messages" => sub {
  bad $Policy, 'my $x = qq(simple)', desc_double, "qq() with simple content";
  bad $Policy, q[my $x = qq(don't)], desc_double, "qq() with apostrophe";
};

subtest "Delimiter optimisation messages with hints" => sub {
  bad $Policy, 'my @x = qw(word(with)parens)', desc_optimal("qw[]"),
    "qw() with parens - hint to use qw[]";

  bad $Policy, 'my @x = qw[word[with]brackets]', desc_use_qw,
    "qw[] with brackets - hint to use qw()";

  bad $Policy, 'my @x = qw{word{with}braces}', desc_use_qw,
    "qw{} with braces - hint to use qw()";

  bad $Policy, 'my @x = qw<word<with>angles>', desc_use_qw,
    "qw<> with angles - hint to use qw()";

  bad $Policy, 'my @x = qw{simple words}', desc_use_qw,
    "qw{} simple - hint to use qw()";

  bad $Policy, 'my $x = q(text(with)parens)', desc_double,
    "q() with parens should use double quotes";

  bad $Policy, 'my $x = qq[text[with]brackets]', desc_double,
    "qq[] with brackets should use double quotes";
};

subtest "Exotic delimiter messages" => sub {
  bad $Policy, 'my $text = q/path\/to\/file/', desc_double,
    "q// with slashes should use double quotes";

  bad $Policy, 'my $text = q|option\|value|', desc_double,
    "q|| with pipes should use double quotes";

  bad $Policy, 'my @x = qw/word\/with\/slashes/', desc_use_qw,
    "qw// with slashes - hint to use qw()";
};

subtest "Combined violation messages" => sub {
  my @violations = find_violations($Policy, <<~'EOCODE');
    my $simple = 'hello';
    my @words = qw{word(with)parens};
    my $ok = "world";
    my @ok_words = qw[more(parens)];
    EOCODE

  is @violations, 2, "Two violations in combined code";

  # The suggestion is in the description, the rationale in the explanation
  like $violations[0]->description, qr/use /,
    "First violation suggests a quoting change";
  like $violations[0]->explanation, qr/consistent/,
    "First violation explains the rationale";
  like $violations[1]->description, qr/use /,
    "Second violation suggests a quoting change";
  like $violations[1]->explanation, qr/consistent/,
    "Second violation explains the rationale";
};

done_testing;
