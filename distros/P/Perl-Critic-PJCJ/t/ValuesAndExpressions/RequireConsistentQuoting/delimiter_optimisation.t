#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing subtest );
use feature      qw( signatures );
use experimental qw( signatures );

# Test the policy directly without using Perl::Critic framework
use lib qw( lib t/lib );
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting ();
use ViolationFinder qw( bad good );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "Delimiter optimisation" => sub {
  # Content with parens should avoid () delimiters
  bad $Policy, 'my @x = qw(word(with)parens)', "use qw[]",
    "qw() with parens should use qw[]";
  good $Policy, 'my @x = qw[word(with)parens]', "qw[] with parens";
  bad $Policy, 'my @x = qw{word(with)parens}', "use qw[]",
    "qw{} with parens should use qw[]";

  # Content with brackets should avoid [] delimiters
  bad $Policy, 'my @x = qw[word[with]brackets]', "use qw()",
    "qw[] with brackets should use qw()";
  good $Policy, 'my @x = qw(word[with]brackets)', "qw() with brackets";
  bad $Policy, 'my @x = qw{word[with]brackets}', "use qw()",
    "qw{} with brackets should use qw()";

  # Content with braces should avoid {} delimiters
  bad $Policy, 'my @x = qw{word{with}braces}', "use qw()",
    "qw{} with braces should use qw()";
  good $Policy, 'my @x = qw(word{with}braces)', "qw() with braces";
  bad $Policy, 'my @x = qw[word{with}braces]', "use qw()",
    "qw[] with braces should use qw()";

  # Content with angles should avoid <> delimiters
  bad $Policy, 'my @x = qw<word<with>angles>', "use qw()",
    "qw<> with angles should use qw()";
  good $Policy, 'my @x = qw(word<with>angles)', "qw() with angles";
  bad $Policy, 'my @x = qw[word<with>angles]', "use qw()",
    "qw[] with angles should use qw()";
  bad $Policy, 'my @x = qw{word<with>angles}', "use qw()",
    "qw{} with angles should use qw()";
};

subtest "Delimiter preference order" => sub {
  # Bracket priority: () > [] > <> > {}
  bad $Policy, 'my @x = qw{simple words}', "use qw()",
    "qw{} should use qw() - () preferred over {}";
  bad $Policy, 'my @x = qw<simple words>', "use qw()",
    "qw<> should use qw() - () preferred over <>";
  bad $Policy, 'my @x = qw[simple words]', "use qw()",
    "qw[] should use qw() - () preferred over []";
  good $Policy, 'my @x = qw(simple words)',
    "qw() is most preferred bracket delimiter";

  # Tie-breaking: when counts equal, prefer () over [] over <> over {}
  bad $Policy, 'my @x = qw{one[bracket}', "use qw()",
    "When tied, () is preferred over {}";
  bad $Policy, 'my @x = qw<one[bracket>', "use qw()",
    "When tied, () is preferred over <>";
  bad $Policy, 'my @x = qw[one[bracket]', "use qw()",
    "When tied, () is preferred over []";
  good $Policy, 'my @x = qw(one[bracket])',
    "() is preferred when all else is equal";

  # Test [] vs <> vs {} preference order
  bad $Policy, 'my @x = qw{one(paren}', "use qw[]",
    "When tied, [] is preferred over {}";
  bad $Policy, 'my @x = qw<one(paren>', "use qw[]",
    "When tied, [] is preferred over <>";
  good $Policy, 'my @x = qw[one(paren)]', "[] is preferred over <> and {}";

  # Test <> vs {} preference order
  bad $Policy, 'my @x = qw{one(paren)[bracket}', "use qw<>",
    "When tied, <> is preferred over {}";
  good $Policy, 'my @x = qw<one(paren)[bracket>', "<> is preferred over {}";

  # When all delimiters appear in content, prefer ()
  bad $Policy, 'my @x = qw{has(parens)[and]<angles>{braces}}', "use qw()",
    "All delimiters present - should use qw()";
  bad $Policy, 'my @x = qw[has(parens)[and]<angles>{braces}]', "use qw()",
    "All delimiters present - should use qw()";
  bad $Policy, 'my @x = qw<has(parens)[and]<angles>{braces}>', "use qw()",
    "All delimiters present - should use qw()";
  good $Policy, 'my @x = qw(has(parens)[and]<angles>{braces})',
    "qw() preferred when all delimiters present";
};

subtest "Already optimal delimiters" => sub {
  # Content with only one type of delimiter that's not the preferred one
  good $Policy, 'my @x = qw[text(only)parens]',
    "[] optimal when content has only parens";
  good $Policy, 'my @x = qw(text[only]brackets])',
    "() optimal when content has only brackets";
  bad $Policy, 'my @x = qw<text<only>angles>', "use qw()",
    "qw<> with angles should use qw()";
  good $Policy, 'my @x = qw(text<only>angles)',
    "() optimal when content has angles";
  good $Policy, 'my @x = qw(text{only}braces)',
    "() optimal when content has only braces";

  # When current delimiter is already optimal
  good $Policy, 'my @x = qw(optimal_choice)',
    "qw() is already optimal for simple content";
  good $Policy, 'my @x = qw(has[only]brackets)', "qw() with only brackets";
  good $Policy, 'my @x = qw[has(only)parens]',   "qw[] with only parens";
};

subtest "Different brackets" => sub {
  bad $Policy, 'my @x = qw{word(with)(many)parens}', "use qw[]",
    "qw{} with many parens should use qw[]";

  # Mixed content - choose preferred delimiter
  bad $Policy, 'my $text = q/has\/slashes(and)parens/', 'use ""',
    "q// should use double quotes";
  good $Policy, 'my $text = "has/slashes(and)parens"',
    '"" optimal - no escaping needed';

  bad $Policy, 'my $text = q(has(parens)\/and\/slashes)', 'use ""',
    "q() should use double quotes";
  good $Policy, 'my $text = "has(parens)/and/slashes"',
    '"" optimal - no escaping needed';
};

subtest "Equal bracket counts" => sub {
  # Tests where all delimiters have same count for sort condition
  # This tests the preference order when counts are equal
  bad $Policy, 'my @x = qw{no_special_chars}', "use qw()",
    "qw{} should use qw() when counts are equal - preference order";
  bad $Policy, 'my @x = qw<no_special_chars>', "use qw()",
    "qw<> should use qw() when counts are equal - preference order";
  bad $Policy, 'my @x = qw[no_special_chars]', "use qw()",
    "qw[] should use qw() when counts are equal - preference order";
  good $Policy, 'my @x = qw(no_special_chars)',
    "qw() is preferred when all delimiters have same count";
};

subtest "Exotic delimiters" => sub {
  bad $Policy, 'my $text = qq/path\/to\/file/', 'use ""',
    "qq// with slashes should use double quotes";
  good $Policy, 'my $text = qq(path"to"file)',
    "qq() optimal when content has double quotes";
  bad $Policy, 'my $text = q|option\|value|', 'use ""',
    "q|| with pipes should use double quotes";
  good $Policy, 'my $text = "option|value"',
    '"" optimal when content has pipes';
  bad $Policy, 'my $text = q"say \"hello\""', "use ''",
    'q"" with quotes should use single quotes';
  bad $Policy, 'my $text = q(say "hello")', "use ''",
    "q() with double quotes should use single quotes";
  bad $Policy, 'my $text = q#path\#to\#file#', 'use ""',
    "q## with hashes should use double quotes";
  good $Policy, 'my $text = "path#to#file"',
    '"" optimal when content has hashes';
  bad $Policy, 'my $text = q!wow\!amazing!', 'use ""',
    "q!! with exclamation marks should use double quotes";
  good $Policy, 'my $text = "wow!amazing"',
    '"" optimal when content has exclamation marks';
  bad $Policy, 'my $text = q%100\%complete%', 'use ""',
    "q%% with percent signs should use double quotes";
  good $Policy, 'my $text = "100%complete"',
    '"" optimal when content has percent signs';
  bad $Policy, 'my $text = q&fish\&chips&', 'use ""',
    "q&& with ampersands should use double quotes";
  good $Policy, 'my $text = "fish&chips"',
    '"" optimal when content has ampersands';
  bad $Policy, 'my $text = q~home\~user~', 'use ""',
    "q~~ with tildes should use double quotes";
  good $Policy, 'my $text = "home~user"',
    '"" optimal when content has tildes';
};

subtest "Priority: fewer escapes" => sub {
  # Rule 2: Always prefer fewer escaped characters
  bad $Policy, 'my $text = q/path\/to\/file/', 'use ""',
    "q// with slashes should use double quotes";
  good $Policy, 'my $text = "path/to/file"',
    '"" optimal when content has slashes';

  # Various quote operators with escaped characters
  bad $Policy, 'my $text = q|option\|value|', 'use ""',
    "q|| with pipes should use double quotes";
  good $Policy, 'my $text = "option|value"',
    '"" optimal when content has pipes';

  bad $Policy, 'my $text = q#path\#to\#file#', 'use ""',
    "q## with hashes should use double quotes";
  good $Policy, 'my $text = "path#to#file"',
    '"" optimal when content has hashes';

  bad $Policy, 'my $text = q!wow\!amazing!', 'use ""',
    "q!! with exclamation should use double quotes";
  good $Policy, 'my $text = "wow!amazing"',
    '"" optimal when content has exclamation';

  bad $Policy, 'my $text = q%100\%complete%', 'use ""',
    "q%% with percent should use double quotes";
  good $Policy, 'my $text = "100%complete"',
    '"" optimal when content has percent';

  bad $Policy, 'my $text = q&fish\&chips&', 'use ""',
    "q&& with ampersand should use double quotes";
  good $Policy, 'my $text = "fish&chips"',
    '"" optimal when content has ampersand';

  bad $Policy, 'my $text = q~home\~user~', 'use ""',
    "q~~ with tilde should use double quotes";
  good $Policy, 'my $text = "home~user"', '"" optimal when content has tilde';

  # qq operators with escaped characters
  bad $Policy, 'my $text = qq/path\/to\/file/', 'use ""',
    "qq// with slashes should use double quotes";
  good $Policy, 'my $text = "path/to/file"',
    '"" optimal for interpolated strings with slashes';

  bad $Policy, 'my $text = qq|option\|value|', 'use ""',
    "qq|| with pipes should use double quotes";
  good $Policy, 'my $text = "option|value"',
    '"" optimal for interpolated strings with pipes';
};

subtest "q() with other delimiter operators" => sub {
  bad $Policy, 'my $x = q(text(with)parens)', 'use ""',
    "q() with parens should use double quotes";
  good $Policy, 'my $x = "text(with)parens"', "double quotes with parens";

  bad $Policy, 'my $x = qq[text[with]brackets]', 'use ""',
    "qq[] with brackets should use double quotes";
  good $Policy, 'my $x = "text[with]brackets"', "qq() with brackets";

  bad $Policy, 'my $x = qx[command[with]brackets]', "use qx()",
    "qx[] with brackets should use qx()";
  good $Policy, 'my $x = qx(command[with]brackets)', "qx() with brackets";
};

subtest "q() delimiter optimisation path coverage" => sub {
  # Test cases to cover when q() is justified and needs delimiter optimisation

  # Test: q() with both quote types - justified, optimise delimiter
  bad $Policy, q(my $text = q[mix 'single' and "double"]), "use q()",
    "q[] with mixed quotes should use q()";

  # Test: q() with single quotes and interpolation - justified,
  # optimise delimiter
  bad $Policy, q(my $text = q|can't use $var|), "use q()",
    "q| with single quotes and interpolation should use q()";

  # Test: q() with double quotes and interpolation - justified,
  # optimise delimiter
  bad $Policy, q(my $text = q|Hello "there" $name|), "use q()",
    "q| with double quotes and interpolation should use q()";

  # Test: q() already using optimal delimiter should not violate
  good $Policy, q[my $text = q(mix 'single' and "double")],
    "q() with mixed quotes and optimal delimiter is justified";

  good $Policy, q[my $text = q(Hello "there" $name)],
    "q() with double quotes and interpolation is justified";
};

done_testing;
