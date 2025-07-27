#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing subtest );
use feature      qw( signatures );
use experimental qw( signatures );

# Test escape sequence handling in quotes
use lib qw( lib t/lib );
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting ();
use ViolationFinder qw( bad good );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "Escaped sigils should suggest double quotes" => sub {
  # In single quotes: '\$' is literally backslash-dollar
  # In double quotes: "\$" is properly escaped dollar

  bad $Policy, q(my $price = "Cost: \$10"), "use ''",
    "Escaped dollar in single quotes should suggest double quotes";

  bad $Policy, q(my $email = "Contact: \@domain"), "use ''",
    "Escaped at in single quotes should suggest double quotes";

  # Mixed escaped and literal content
  bad $Policy, q(my $mixed = "\$escaped and literal text"), "use ''",
    "Escaped sigils with text should suggest single quotes";
};

subtest "Other escape sequences in single quotes" => sub {
  # Single quotes treat these as literal, double quotes interpret them

  good $Policy, q(my $text = "Line 1\nLine 2"),
    "Escape sequences in double quotes are acceptable";

  good $Policy, q(my $text = "Tab\there"),
    "Tab escape sequence in double quotes is acceptable";

  good $Policy, q(my $path = "C:\new\folder"),
    "Path with backslashes in double quotes is acceptable";
};

subtest "True variable interpolation should keep single quotes" => sub {
  # These should remain single quotes to prevent interpolation

  good $Policy, q(my $literal = '$var should not interpolate'),
    "Literal variable reference should stay single quotes";

  good $Policy, q(my $array = '@array should not interpolate'),
    "Literal array reference should stay single quotes";

  good $Policy, q(my $complex = '$hash{key} should not interpolate'),
    "Complex variable reference should stay single quotes";
};

subtest "Escape sequences in single quotes should NOT suggest double quotes" =>
  sub {
    # Single quotes with literal backslash-escape sequences should NOT suggest
    # double quotes because that would change their meaning from literal to
    # escaped

    # Literal backslash-n in single quotes should stay single quotes
    # (in '' it's literal \n, in "" it would become newline)
    good $Policy, q(my $literal_newline = 'text with \\n literal'),
    'Literal \n in single quotes should stay single quotes';

    # Literal backslash-t in single quotes should stay single quotes
    # (in '' it's literal \t, in "" it would become tab)
    good $Policy, q(my $literal_tab = 'text with \\t literal'),
    'Literal \t in single quotes should stay single quotes';

    # Literal backslash-dollar in single quotes should stay single quotes
    # (in '' it's literal \$, in "" it would become escaped $)
    good $Policy, q(my $literal_dollar = 'price: \\$5.00'),
    'Literal \$ in single quotes should stay single quotes';

    # Literal backslash-at in single quotes should stay single quotes
    # (in '' it's literal \@, in "" it would become escaped @)
    good $Policy, q(my $literal_at = 'email: user\\@domain.com'),
    'Literal \@ in single quotes should stay single quotes';

    # Complex case with multiple literal escapes should stay single quotes
    good $Policy, q(my $complex = 'path: C:\\new\\folder with \\$var'),
    "Multiple literal escapes in single quotes should stay single quotes";
  };

subtest "All Perl escape sequences should stay in single quotes" => sub {
  # Test all escape sequences from perlop documentation

  # Single character escapes: \t \n \r \f \b \a \e
  good $Policy, q(my $text = 'Line with \\r carriage return'),
    'Literal \r in single quotes should stay single quotes';
  good $Policy, q(my $text = 'Form \\f feed here'),
    'Literal \f in single quotes should stay single quotes';
  good $Policy, q(my $text = 'Backspace \\b here'),
    'Literal \b in single quotes should stay single quotes';
  good $Policy, q(my $text = 'Bell \\a sound'),
    'Literal \a in single quotes should stay single quotes';
  good $Policy, q(my $text = 'Escape \\e sequence'),
    'Literal \e in single quotes should stay single quotes';

  # Hex escapes: \x1b \xff \x{263A}
  good $Policy, q(my $hex = 'Hex \\x1b escape'),
    'Literal \x hex escape should stay single quotes';
  good $Policy, q(my $hex = 'Hex \\xff value'),
    'Literal \xff hex escape should stay single quotes';
  good $Policy, q(my $hex = 'Unicode \\x{263A} smiley'),
    'Literal \x{} hex escape should stay single quotes';

  # Octal escapes: \033 \377 \o{033}
  good $Policy, q(my $oct = 'Octal \\033 escape'),
    'Literal \033 octal escape should stay single quotes';
  good $Policy, q(my $oct = 'Octal \\377 max'),
    'Literal \377 octal escape should stay single quotes';
  good $Policy, q(my $oct = 'Octal \\o{033} braced'),
    'Literal \o{} octal escape should stay single quotes';

  # Control characters: \c[ \cA \c@
  good $Policy, q(my $ctrl = 'Control \\c[ char'),
    'Literal \c control char should stay single quotes';
  good $Policy, q(my $ctrl = 'Control \\cA char'),
    'Literal \cA control char should stay single quotes';
  good $Policy, q(my $ctrl = 'Control \\c@ null'),
    'Literal \c@ control char should stay single quotes';

  # Named Unicode: \N{name} \N{U+263A}
  good $Policy, q(my $named = 'Named \\N{SMILEY} char'),
    'Literal \N{name} escape should stay single quotes';
  good $Policy, q(my $named = 'Unicode \\N{U+263A} point'),
    'Literal \N{U+} escape should stay single quotes';
};

subtest "q() with escape sequences should stay q()" => sub {
  # q() behaves like single quotes - escape sequences are literal
  # So q() with escape sequences should be preserved to maintain literal meaning

  # Single character escapes in q()
  good $Policy, q[my $text = q(Line with \\n newline)],
    'q() with literal \n should stay q()';
  good $Policy, q[my $text = q(Tab \\t here)],
    'q() with literal \t should stay q()';
  good $Policy, q[my $text = q(Return \\r here)],
    "q() with literal \r should stay q()";

  # Variable sigils in q() - these are literal backslash-dollar/at
  # Since \$ in q() is literal (two characters), it's preserved
  good $Policy, q[my $price = q(Cost: \\$5.00)],
    'q() with literal \$ should stay q()';
  good $Policy, q[my $email = q(user\\@domain.com)],
    'q() with literal \@ should stay q()';

  # Hex/octal escapes in q()
  good $Policy, q[my $hex = q(Hex \\x1b escape)],
    'q() with literal \x hex should stay q()';
  good $Policy, q[my $oct = q(Octal \\033 escape)],
    'q() with literal \033 should stay q()';

  # Control and named escapes in q()
  good $Policy, q<my $ctrl = q(Control \\c[ char)>,
    'q() with literal \c should stay q()';
  good $Policy, q[my $named = q(Named \\N{SMILEY} char)],
    "q() with literal \\N should stay q()";
};

subtest "qq() with escape sequences should stay qq()" => sub {
  # qq() behaves like double quotes - escape sequences are interpreted
  # So qq() with escape sequences should be preserved to maintain
  # interpreted meaning

  # Single character escapes in qq()
  good $Policy, q[my $text = qq(Line with \\n newline)],
    'qq() with interpreted \n should stay qq()';
  good $Policy, q[my $text = qq(Tab \\t here)],
    'qq() with interpreted \t should stay qq()';
  good $Policy, q[my $text = qq(Return \\r here)],
    'qq() with interpreted \r should stay qq()';

  # Variable sigils in qq() - these escape the sigils for literal output
  # Since \$ in qq() produces a literal $, single quotes would work too
  bad $Policy, q[my $price = qq(Cost: \\$5.00)], "use ''",
    'qq() with escaped \$ should suggest single quotes';
  bad $Policy, q[my $email = qq(user\\@domain.com)], "use ''",
    'qq() with escaped \@ should suggest single quotes';

  # Hex/octal escapes in qq()
  good $Policy, q[my $hex = qq(Hex \\x1b escape)],
    'qq() with interpreted \x hex should stay qq()';
  good $Policy, q[my $oct = qq(Octal \\033 escape)],
    'qq() with interpreted \033 should stay qq()';

  # Control and named escapes in qq()
  good $Policy, q<my $ctrl = qq(Control \\c[ char)>,
    'qq() with interpreted \c should stay qq()';
  good $Policy, q[my $named = qq(Named \\N{SMILEY} char)],
    "qq() with interpreted \\N should stay qq()";
};

subtest "Variables in single quotes are not suggested for interpolation" =>
  sub {
    # These test that the policy doesn't suggest interpolating actual variables
    # Variables in single quotes should stay literal (not interpolated)

    # Variable that exists in scope should not suggest interpolation
    good $Policy, q(my $x = '$var literal'),
    "Variables in single quotes should stay literal";

    # Array reference should not suggest interpolation
    good $Policy, q(my $x = '@arr literal'),
    "Array refs in single quotes should stay literal";

    # Hash reference should not suggest interpolation
    good $Policy, q(my $x = '$hash{key} literal'),
    "Hash refs in single quotes should stay literal";

    # Email addresses with @ should not suggest interpolation
    good $Policy, q(my $email = 'user@domain.com'),
    "Email addresses should stay in single quotes";
  };

subtest "Edge cases with backslashes" => sub {
  # Test boundary conditions

  # Original test - let's see if this uncovers a bug
  good $Policy, 'my $backslash = "Just \\ backslash"',
    "Escaped backslash in double quotes is acceptable";

  bad $Policy, q(my $backslash = 'Just \\ backslash'), 'use ""',
    "Literal backslashes in single quotes should suggest double quotes";

  good $Policy, q(my $quote = 'Has "double" quotes'),
    "Single quotes justified by containing double quotes";

  # Test the two valid single-quote escapes
  # Actually, escaped single quotes should suggest double quotes
  # for better readability
  good $Policy, q(my $escaped_quote = "Don't worry"),
    "Simple apostrophe in double quotes is acceptable";
};

subtest "Additional escape sequence tests" => sub {
  # Test cases that might confuse the PPI parser in would_interpolate
  # Complex strings that might not parse correctly in double quotes
  good $Policy, q(my $x = 'text with " and \\ and other escapes'),
    "Single quotes for complex escape sequences";

  # Single quotes with escape sequences should stay single quotes
  # Note: strings with escape sequences in single quotes should stay single
  # quotes because \n has different meanings: literal in '', newline in ""
  good $Policy, q(my $x = 'text with \n newline but no interpolation'),
    "Single quotes with escape sequences should stay single quotes";
};

done_testing;
