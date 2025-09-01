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

subtest "q() operator" => sub {
  # Simple content should use double quotes instead of q()
  bad $Policy, 'my $x = q(simple)', 'use ""',
    "q() simple string should use double quotes";
  bad $Policy, 'my $x = q(simple123)', 'use ""',
    "q() with simple alphanumeric content should use double quotes";
  bad $Policy, 'my $x = q(literal)', 'use ""',
    'q() should use "" for literal content';

  # When q() would interpolate, should use single quotes
  bad $Policy, 'my $x = q(literal $var here)', "use ''",
    'q() with literal $ should use single quotes';
  bad $Policy, 'my $x = q(would interpolate $var)', "use ''",
    "q() should use single quotes when content would interpolate";
  bad $Policy, 'my $x = q(interpolates $var)', "use ''",
    "q() should use single quotes when content would interpolate";
  bad $Policy, 'my $x = q(user@domain.com)', "use ''",
    'q() with @ variable should use single quotes';
  bad $Policy, 'my $x = q(price: \$5.00)', "use ''",
    "q() with escaped dollar should use single quotes";
  bad $Policy, 'my $x = q(email: \@domain.com)', "use ''",
    "q() with escaped at-sign should use single quotes";
  bad $Policy, 'my $x = q(path\to\$file)', "use ''",
    "q() with backslash before dollar should use single quotes";

  # When q() is justified
  good $Policy, q[my $x = q(has 'single' and "double" quotes)],
    "q() is justified when content has both quote types";
  bad $Policy, 'my $x = q(has "only" double quotes)', "use ''",
    "q() with only double quotes should recommend single quotes";

  # When q() is justified but delimiter can be optimised
  bad $Policy, q(my $x = q{has 'single' and "double" quotes}), "use q()",
    "q{} with both quote types should optimise delimiter to q()";
  bad $Policy, q(my $x = q[has 'single' and "double" quotes]), "use q()",
    "q[] with both quote types should optimise delimiter to q()";

  # Test case that should reach the has_quotes branch in q literal
  good $Policy, q[my $x = q(string with both 'single' and "double" quotes)],
    "q() with both quote types using optimal delimiter";

  # Different q() delimiters
  bad $Policy, q(my $x = q'simple'), 'use ""',
    "q'' should use double quotes for simple content";
  bad $Policy, 'my $x = q/simple/', 'use ""',
    "q// should use double quotes for simple content";
  bad $Policy, 'my $x = q(literal$x)', "use ''",
    "q() should use single quotes for literal content";
  bad $Policy, 'my $x = q/literal$x/', "use ''",
    "q// should use single quotes";

  # Single bracket characters should suggest double quotes (simple content)
  bad $Policy, 'my $x = q{(}', 'use ""',
    "q{} with single open paren should use double quotes";
  bad $Policy, 'my $x = q<[>', 'use ""',
    "q<> with single open bracket should use double quotes";
  bad $Policy, 'my $x = q{@x(}', "use ''",
    "q{} with @ and open paren should use single quotes";
  bad $Policy, 'my $x = q{$x(}', "use ''",
    'q{} with $ and open paren should use single quotes';

  # Pairs of delimiters should suggest double quotes (simple content)
  bad $Policy, 'my $x = q{()}', 'use ""',
    "q{} with empty parens should use double quotes";
  bad $Policy, 'my $x = q{[]}', 'use ""',
    "q{} with empty brackets should use double quotes";
  bad $Policy, 'my $x = q{<>}', 'use ""',
    "q{} with empty angles should use double quotes";
  bad $Policy, 'my $x = q{{}}', 'use ""',
    "q{} with empty braces should use double quotes";
  bad $Policy, 'my $x = q{()()}', 'use ""',
    "q{} with double parens should use double quotes";
  bad $Policy, 'my $x = q{[][]}', 'use ""',
    "q{} with double brackets should use double quotes";
};

subtest "qq() operator" => sub {
  # Should use double quotes instead of qq()
  bad $Policy, 'my $x = qq(simple)', 'use ""',
    "qq() should use double quotes for simple content";
  bad $Policy, 'my $x = qq/hello/', 'use ""', "qq// should use double quotes";
  bad $Policy, q(my $x = qq'simple'), 'use ""',
    "qq'' should use double quotes for simple content";
  bad $Policy, 'my $x = qq/simple/', 'use ""',
    "qq// should use double quotes for simple content";
  bad $Policy, 'my $x = qq(simple)', 'use ""',
    "qq() should use double quotes for simple content";

  # qq() with content containing "delimiter characters" should still suggest ""
  bad $Policy, 'my $x = qq(content(with)parens)', 'use ""',
    "qq() with parens should use double quotes";
  bad $Policy, 'my $x = qq/path/to/file/', 'use ""',
    "qq// with slashes should use double quotes";
  bad $Policy, 'my $x = qq#hash#tag#', 'use ""',
    "qq## with hashes should use double quotes";
  bad $Policy, 'my $x = qq{simple[brackets]}', 'use ""',
    "qq{} with brackets should use double quotes";

  # When qq() is appropriate (has double quotes)
  good $Policy, 'my $x = qq(has "double" quotes)',
    "qq() appropriate when content has double quotes";

  # When qq() is justified due to special characters and optimal delimiter
  good $Policy, 'my $x = qq(string with $var and "quotes")',
    "qq() justified when content has interpolation and double quotes";

  # When qq() has single quotes (special chars) but double quotes would be fine
  good $Policy, q[my $x = qq(string with 'single' quotes)],
    "qq() justified when content has single quotes that need interpolation";

  # When qq() is justified due to single quotes and uses optimal delimiter
  good $Policy, q[my $x = qq(interpolated $var with 'quotes')],
    "qq() justified when content has interpolation and single quotes";

  # When qq() suggestion comes from double quotes analysis
  good $Policy, q[my $x = qq(content with "double" and 'single' quotes)],
    "qq() justified when content has both quote types needing interpolation";
};

subtest "Priority rules" => sub {
  # Rule 1: Prefer interpolating quotes unless strings shouldn't interpolate
  bad $Policy, q(my $x = 'simple'), 'use ""',
    "Simple string should use double quotes";
  good $Policy, 'my $x = "simple"', "Simple string with double quotes";
  good $Policy, q(my $x = 'literal$var'),
    'String with literal $ should use single quotes';
  good $Policy, q(my $x = 'literal@var'),
    'String with literal @ should use single quotes';

  # Rule 3: Prefer "" to qq
  bad $Policy, 'my $x = qq(simple)', 'use ""',
    "qq() should use double quotes for simple content";
  good $Policy, 'my $x = "simple"', "Double quotes preferred over qq()";

  # Rule 4: Prefer '' to q
  bad $Policy, 'my $x = q(literal$x)', "use ''",
    "q() should use single quotes for literal content";
  good $Policy, q(my $x = 'literal$x'), "Single quotes preferred over q()";
};

subtest "Additional q() operator coverage tests" => sub {
  # Try edge case with @ but no $ and double quotes
  bad $Policy, 'my $x = q(user@domain.com "needs" quoting)', "use ''",
    'q() with @ and double quotes should suggest single quotes';

  # Try case that might have interpolation issues with complex content
  bad $Policy, 'my $x = q(complex@email.com with "embedded quotes" text)',
    "use ''", 'q() with @ and double quotes should suggest single quotes';

  # Edge case: content that might confuse the would_interpolate method
  # q() with \@ is preserved because \@ would have different meaning
  # in double quotes, but delimiter should be optimised
  bad $Policy, 'my $x = q((\@));', "use ''",
    q[q() with escaped @ and parens should optimise delimiter to ''];

  bad $Policy, 'my $x = q(\@escaped at sign with "quotes")', "use ''",
    'q() with escaped @ should suggest single quotes';

  # Test q() with escaped sigils and quotes
  # q() with \$ or \@ is preserved because they would have different
  # meaning in double quotes
  bad $Policy, 'my $x = q(\$var and "quotes" together)', "use ''",
    "q() with escaped dollar should suggest single quotes";

  bad $Policy, 'my $x = q(\@var and "quotes" together)', "use ''",
    "q() with escaped at should suggest single quotes";

  # Test q() with content that might not be handled by early returns
  bad $Policy, 'my $x = q(text with "quotes" and \\ escapes)', "use ''",
    "q() with quotes and escapes should suggest single quotes";
};

done_testing;
