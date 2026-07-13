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
  desc_double
  desc_optimal
  desc_single
);
use ViolationFinder qw( bad good );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "q() operator" => sub {
  # Simple content should use double quotes instead of q()
  bad $Policy, 'my $x = q(simple)', desc_double,
    "q() simple string should use double quotes";
  bad $Policy, 'my $x = q(simple123)', desc_double,
    "q() with simple alphanumeric content should use double quotes";
  bad $Policy, 'my $x = q(literal)', desc_double,
    'q() should use "" for literal content';

  # When q() would interpolate, should use single quotes
  bad $Policy, 'my $x = q(literal $var here)', desc_single,
    'q() with literal $ should use single quotes';
  bad $Policy, 'my $x = q(would interpolate $var)', desc_single,
    "q() should use single quotes when content would interpolate";
  bad $Policy, 'my $x = q(interpolates $var)', desc_single,
    "q() should use single quotes when content would interpolate";
  bad $Policy, 'my $x = q(user@domain.com)', desc_single,
    'q() with @ variable should use single quotes';
  bad $Policy, 'my $x = q(price: \$5.00)', desc_single,
    "q() with escaped dollar should use single quotes";
  bad $Policy, 'my $x = q(email: \@domain.com)', desc_single,
    "q() with escaped at-sign should use single quotes";
  bad $Policy, 'my $x = q(path\to\$file)', desc_single,
    "q() with backslash before dollar should use single quotes";

  # When q() is justified
  good $Policy, q[my $x = q(has 'single' and "double" quotes)],
    "q() is justified when content has both quote types";
  bad $Policy, 'my $x = q(has "only" double quotes)', desc_single,
    "q() with only double quotes should recommend single quotes";

  # When q() is justified but delimiter can be optimised
  bad $Policy, q(my $x = q{has 'single' and "double" quotes}),
    desc_optimal("q()"),
    "q{} with both quote types should optimise delimiter to q()";
  bad $Policy, q(my $x = q[has 'single' and "double" quotes]),
    desc_optimal("q()"),
    "q[] with both quote types should optimise delimiter to q()";

  # Test case that should reach the has_quotes branch in q literal
  good $Policy, q[my $x = q(string with both 'single' and "double" quotes)],
    "q() with both quote types using optimal delimiter";

  # Different q() delimiters
  bad $Policy, q(my $x = q'simple'), desc_double,
    "q'' should use double quotes for simple content";
  bad $Policy, 'my $x = q/simple/', desc_double,
    "q// should use double quotes for simple content";
  bad $Policy, 'my $x = q(literal$x)', desc_single,
    "q() should use single quotes for literal content";
  bad $Policy, 'my $x = q/literal$x/', desc_single,
    "q// should use single quotes";

  # Single bracket characters should suggest double quotes (simple content)
  bad $Policy, 'my $x = q{(}', desc_double,
    "q{} with single open paren should use double quotes";
  bad $Policy, 'my $x = q<[>', desc_double,
    "q<> with single open bracket should use double quotes";
  bad $Policy, 'my $x = q{@x(}', desc_single,
    "q{} with @ and open paren should use single quotes";
  bad $Policy, 'my $x = q{$x(}', desc_single,
    'q{} with $ and open paren should use single quotes';

  # Pairs of delimiters should suggest double quotes (simple content)
  bad $Policy, 'my $x = q{()}', desc_double,
    "q{} with empty parens should use double quotes";
  bad $Policy, 'my $x = q{[]}', desc_double,
    "q{} with empty brackets should use double quotes";
  bad $Policy, 'my $x = q{<>}', desc_double,
    "q{} with empty angles should use double quotes";
  bad $Policy, 'my $x = q{{}}', desc_double,
    "q{} with empty braces should use double quotes";
  bad $Policy, 'my $x = q{()()}', desc_double,
    "q{} with double parens should use double quotes";
  bad $Policy, 'my $x = q{[][]}', desc_double,
    "q{} with double brackets should use double quotes";
};

subtest "qq() operator" => sub {
  # Should use double quotes instead of qq()
  bad $Policy, 'my $x = qq(simple)', desc_double,
    "qq() should use double quotes for simple content";
  bad $Policy, 'my $x = qq/hello/', desc_double,
    "qq// should use double quotes";
  bad $Policy, q(my $x = qq'simple'), desc_double,
    "qq'' should use double quotes for simple content";
  bad $Policy, 'my $x = qq/simple/', desc_double,
    "qq// should use double quotes for simple content";
  bad $Policy, 'my $x = qq(simple)', desc_double,
    "qq() should use double quotes for simple content";

  # qq() with content containing "delimiter characters" should still suggest ""
  bad $Policy, 'my $x = qq(content(with)parens)', desc_double,
    "qq() with parens should use double quotes";
  bad $Policy, 'my $x = qq/path/to/file/', desc_double,
    "qq// with slashes should use double quotes";
  bad $Policy, 'my $x = qq#hash#tag#', desc_double,
    "qq## with hashes should use double quotes";
  bad $Policy, 'my $x = qq{simple[brackets]}', desc_double,
    "qq{} with brackets should use double quotes";

  # qq() with only double quotes should use single quotes
  bad $Policy, 'my $x = qq(has "double" quotes)', desc_single,
    "qq() with only double quotes should use single quotes";
  bad $Policy, 'my $x = qq(<td class="%s">T</td>)', desc_single,
    "qq() with HTML containing double quotes should use single quotes";

  # When qq() is justified due to special characters and optimal delimiter
  good $Policy, 'my $x = qq(string with $var and "quotes")',
    "qq() justified when content has interpolation and double quotes";

  # Apostrophes need no escaping in double quotes, so "" is still preferred
  bad $Policy, q[my $x = qq(string with 'single' quotes)], desc_double,
    "qq() with only single quotes should use double quotes";
  bad $Policy, q[my $x = qq(interpolated $var with 'quotes')], desc_double,
    "qq() with interpolation and single quotes should use double quotes";

  bad $Policy, q[my $x = qq(don't)], desc_double,
    "qq() with apostrophe should use double quotes";
  bad $Policy, q(my $x = qq[don't]), desc_double,
    "qq[] with apostrophe should use double quotes directly";

  # When qq() suggestion comes from double quotes analysis
  good $Policy, q[my $x = qq(content with "double" and 'single' quotes)],
    "qq() justified when content has both quote types needing interpolation";
};

subtest "Priority rules" => sub {
  # Rule 1: Prefer interpolating quotes unless strings shouldn't interpolate
  bad $Policy, q(my $x = 'simple'), desc_double,
    "Simple string should use double quotes";
  good $Policy, 'my $x = "simple"', "Simple string with double quotes";
  good $Policy, q(my $x = 'literal$var'),
    'String with literal $ should use single quotes';
  good $Policy, q(my $x = 'literal@var'),
    'String with literal @ should use single quotes';

  # Rule 3: Prefer "" to qq
  bad $Policy, 'my $x = qq(simple)', desc_double,
    "qq() should use double quotes for simple content";
  good $Policy, 'my $x = "simple"', "Double quotes preferred over qq()";

  # Rule 4: Prefer '' to q
  bad $Policy, 'my $x = q(literal$x)', desc_single,
    "q() should use single quotes for literal content";
  good $Policy, q(my $x = 'literal$x'), "Single quotes preferred over q()";
};

subtest "Additional q() operator coverage tests" => sub {
  # Try edge case with @ but no $ and double quotes
  bad $Policy, 'my $x = q(user@domain.com "needs" quoting)', desc_single,
    'q() with @ and double quotes should suggest single quotes';

  # Try case that might have interpolation issues with complex content
  bad $Policy, 'my $x = q(complex@email.com with "embedded quotes" text)',
    desc_single, 'q() with @ and double quotes should suggest single quotes';

  # Edge case: content that might confuse the would_interpolate method
  # q() with \@ is preserved because \@ would have different meaning
  # in double quotes, but delimiter should be optimised
  bad $Policy, 'my $x = q((\@));', desc_single,
    q[q() with escaped @ and parens should optimise delimiter to ''];

  bad $Policy, 'my $x = q(\@escaped at sign with "quotes")', desc_single,
    'q() with escaped @ should suggest single quotes';

  # Test q() with escaped sigils and quotes
  # q() with \$ or \@ is preserved because they would have different
  # meaning in double quotes
  bad $Policy, 'my $x = q(\$var and "quotes" together)', desc_single,
    "q() with escaped dollar should suggest single quotes";

  bad $Policy, 'my $x = q(\@var and "quotes" together)', desc_single,
    "q() with escaped at should suggest single quotes";

  # Test q() with content that might not be handled by early returns
  bad $Policy, 'my $x = q(text with "quotes" and \\ escapes)', desc_single,
    "q() with quotes and escapes should suggest single quotes";
};

done_testing;
