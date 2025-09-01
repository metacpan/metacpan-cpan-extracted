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

  bad $Policy, 'my $price = "Cost: \$10"', "use ''",
    "Escaped dollar in single quotes should suggest single quotes";

  bad $Policy, 'my $email = "Contact: \@domain"', "use ''",
    "Escaped at in single quotes should suggest single quotes";

  # Mixed escaped and literal content
  bad $Policy, 'my $mixed = "\$escaped and literal text"', "use ''",
    "Escaped sigils with text should suggest single quotes";
};

subtest "Other escape sequences in single quotes" => sub {
  # Single quotes treat these as literal, double quotes interpret them

  good $Policy, 'my $text = "Line 1\nLine 2"',
    "Escape sequences in double quotes are acceptable";

  good $Policy, 'my $text = "Tab\there"',
    "Tab escape sequence in double quotes is acceptable";

  good $Policy, 'my $path = "C:\new\folder"',
    "Path with backslashes in double quotes is acceptable";
};

subtest "True variable interpolation should keep single quotes" => sub {
  # These should remain single quotes to prevent interpolation

  good $Policy, q(my $literal = '$var should not interpolate'),
    "Literal variable reference should stay single quotes";

  good $Policy, 'my $array = \'@array should not interpolate\'',
    "Literal array reference should stay single quotes";

  good $Policy, 'my $complex = \'$hash{key} should not interpolate\'',
    "Complex variable reference should stay single quotes";
};

subtest "Escape sequences in single quotes should NOT suggest double quotes" =>
  sub {
    # Single quotes with literal backslash-escape sequences should NOT suggest
    # double quotes because that would change their meaning from literal to
    # escaped

    # Literal backslash-n in single quotes should stay single quotes
    # (in '' it's literal \n, in "" it would become newline)
    good $Policy, 'my $literal_newline = \'text with \\n literal\'',
    'Literal \n in single quotes should stay single quotes';

    # Literal backslash-t in single quotes should stay single quotes
    # (in '' it's literal \t, in "" it would become tab)
    good $Policy, 'my $literal_tab = \'text with \\t literal\'',
    'Literal \t in single quotes should stay single quotes';

    # Literal backslash-dollar in single quotes should stay single quotes
    # (nothing to do with the backslash, it's the interpolation of $)
    good $Policy, 'my $literal_dollar = \'price: \\$5.00\'',
    'Literal \$ in single quotes should stay single quotes';

    # Literal backslash-at in single quotes should stay single quotes
    # (in '' it's literal \@, in "" it would become escaped @)
    good $Policy, 'my $literal_at = \'email: user\\@domain.com\'',
    'Literal \@ in single quotes should stay single quotes';

    # Complex case with multiple literal escapes should stay single quotes
    good $Policy, 'my $complex = \'path: C:\\new\\folder with \\$var\'',
    "Multiple literal escapes in single quotes should stay single quotes";
  };

subtest "All Perl escape sequences should stay in single quotes" => sub {
  # Test all escape sequences from perlop documentation

  # Single character escapes: \t \n \r \f \b \a \e
  good $Policy, 'my $text = \'Line with \\r carriage return\'',
    'Literal \r in single quotes should stay single quotes';
  good $Policy, 'my $text = \'Form \\f feed here\'',
    'Literal \f in single quotes should stay single quotes';
  good $Policy, 'my $text = \'Backspace \\b here\'',
    'Literal \b in single quotes should stay single quotes';
  good $Policy, 'my $text = \'Bell \\a sound\'',
    'Literal \a in single quotes should stay single quotes';
  good $Policy, 'my $text = \'Escape \\e sequence\'',
    'Literal \e in single quotes should stay single quotes';

  # Hex escapes: \x1b \xff \x{263A}
  good $Policy, 'my $hex = \'Hex \\x1b escape\'',
    'Literal \x hex escape should stay single quotes';
  good $Policy, 'my $hex = \'Hex \\xff value\'',
    'Literal \xff hex escape should stay single quotes';
  good $Policy, 'my $hex = \'Unicode \\x{263A} smiley\'',
    'Literal \x{} hex escape should stay single quotes';

  # Octal escapes: \033 \377 \o{033}
  good $Policy, 'my $oct = \'Octal \\033 escape\'',
    'Literal \033 octal escape should stay single quotes';
  good $Policy, 'my $oct = \'Octal \\377 max\'',
    'Literal \377 octal escape should stay single quotes';
  good $Policy, 'my $oct = \'Octal \\o{033} braced\'',
    'Literal \o{} octal escape should stay single quotes';

  # Control characters: \c[ \cA \c@
  good $Policy, 'my $ctrl = \'Control \\c[ char\'',
    'Literal \c control char should stay single quotes';
  good $Policy, 'my $ctrl = \'Control \\cA char\'',
    'Literal \cA control char should stay single quotes';
  good $Policy, 'my $ctrl = \'Control \\c@ null\'',
    'Literal \c@ control char should stay single quotes';

  # Named Unicode: \N{name} \N{U+263A}
  good $Policy, 'my $named = \'Named \\N{SMILEY} char\'',
    'Literal \N{name} escape should stay single quotes';
  good $Policy, 'my $named = \'Unicode \\N{U+263A} point\'',
    'Literal \N{U+} escape should stay single quotes';
};

subtest "q() with escape sequences should recommend changes" => sub {
  # q() behaves like single quotes - escape sequences are literal
  # So q() with escape sequences should be preserved to maintain literal meaning

  # Single character escapes in q()
  bad $Policy, 'my $text = q(Line with \\n newline)', 'use ""',
    'q() with literal \n should suggest double quotes';
  bad $Policy, 'my $text = q(Tab \\t here)', 'use ""',
    'q() with literal \t should suggest double quotes';
  bad $Policy, 'my $text = q(Return \\r here)', 'use ""',
    'q() with literal \r should suggest double quotes';

  # Variable sigils in q() - these are literal backslash-dollar/at
  # Since \$ in q() is literal (two characters), it's preserved
  bad $Policy, 'my $price = q(Cost: \\$5.00)', "use ''",
    'q() with literal \$ should suggest single quotes';
  bad $Policy, 'my $email = q(user\\@domain.com)', "use ''",
    'q() with literal \@ should suggest single quotes';

  # Hex/octal escapes in q()
  bad $Policy, 'my $hex = q(Hex \\x1b escape)', 'use ""',
    'q() with literal \x hex should suggest double quotes';
  bad $Policy, 'my $oct = q(Octal \\033 escape)', 'use ""',
    'q() with literal \033 should suggest double quotes';

  # Control and named escapes in q()
  bad $Policy, 'my $ctrl = q(Control \\c[ char)', 'use ""',
    'q() with literal \c should suggest double quotes';
  bad $Policy, 'my $named = q(Named \\N{SMILEY} char)', 'use ""',
    "q() with literal \\N should suggest double quotes";
};

subtest "qq() with escape sequences should stay qq()" => sub {
  # qq() behaves like double quotes - escape sequences are interpreted
  # So qq() with escape sequences should be preserved to maintain
  # interpreted meaning

  # Single character escapes in qq()
  good $Policy, 'my $text = qq(Line with \\n newline)',
    'qq() with interpreted \n should stay qq()';
  good $Policy, 'my $text = qq(Tab \\t here)',
    'qq() with interpreted \t should stay qq()';
  good $Policy, 'my $text = qq(Return \\r here)',
    'qq() with interpreted \r should stay qq()';

  # Variable sigils in qq() - these escape the sigils for literal output
  # Since \$ in qq() produces a literal $, single quotes would work too
  bad $Policy, 'my $price = qq(Cost: \\$5.00)', "use ''",
    'qq() with escaped \$ should suggest single quotes';
  bad $Policy, 'my $email = qq(user\\@domain.com)', "use ''",
    'qq() with escaped \@ should suggest single quotes';

  # Hex/octal escapes in qq()
  good $Policy, 'my $hex = qq(Hex \\x1b escape)',
    'qq() with interpreted \x hex should stay qq()';
  good $Policy, 'my $oct = qq(Octal \\033 escape)',
    'qq() with interpreted \033 should stay qq()';

  # Control and named escapes in qq()
  good $Policy, 'my $ctrl = qq(Control \\c[ char)',
    'qq() with interpreted \c should stay qq()';
  good $Policy, 'my $named = qq(Named \\N{SMILEY} char)',
    "qq() with interpreted \\N should stay qq()";
};

subtest "Variables in single quotes are not suggested for interpolation" =>
  sub {
    # These test that the policy doesn't suggest interpolating actual variables
    # Variables in single quotes should stay literal (not interpolated)

    # Variable that exists in scope should not suggest interpolation
    good $Policy, 'my $x = \'$var literal\'',
    "Variables in single quotes should stay literal";

    # Array reference should not suggest interpolation
    good $Policy, 'my $x = \'@arr literal\'',
    "Array refs in single quotes should stay literal";

    # Hash reference should not suggest interpolation
    good $Policy, 'my $x = \'$hash{key} literal\'',
    "Hash refs in single quotes should stay literal";

    # Email addresses with @ should not suggest interpolation
    good $Policy, 'my $email = \'user@domain.com\'',
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
  good $Policy, 'my $x = \'text with \n newline but no interpolation\'',
    "Single quotes with escape sequences should stay single quotes";
};

subtest "Double quotes containing only escape sequences" => sub {
  # Test that double-quoted strings containing ONLY escape sequences
  # are correctly handled and not suggested to use single quotes

  # Single character escapes
  good $Policy, 'my $newline = "\n"',
    "Double quotes with only newline escape should stay double quotes";
  good $Policy, 'my $tab = "\t"',
    "Double quotes with only tab escape should stay double quotes";
  good $Policy, 'my $return = "\r"',
    "Double quotes with only carriage return escape should stay double quotes";
  good $Policy, 'my $form = "\f"',
    "Double quotes with only form feed escape should stay double quotes";
  good $Policy, 'my $backspace = "\b"',
    "Double quotes with only backspace escape should stay double quotes";
  good $Policy, 'my $bell = "\a"',
    "Double quotes with only bell/alert escape should stay double quotes";
  good $Policy, 'my $escape = "\e"',
    "Double quotes with only escape character should stay double quotes";

  # Hex escapes
  good $Policy, 'my $hex = "\x1b"',
    "Double quotes with only hex escape should stay double quotes";
  good $Policy, 'my $hex = "\xff"',
    "Double quotes with only hex FF escape should stay double quotes";
  good $Policy, 'my $hex = "\x{263A}"',
    "Double quotes with only hex unicode escape should stay double quotes";

  # Octal escapes
  good $Policy, 'my $oct = "\033"',
    "Double quotes with only octal escape should stay double quotes";
  good $Policy, 'my $oct = "\377"',
    "Double quotes with only octal 377 escape should stay double quotes";
  good $Policy, 'my $oct = "\o{033}"',
    "Double quotes with only braced octal escape should stay double quotes";

  # Control characters
  good $Policy, 'my $ctrl = "\c["',
    "Double quotes with only control escape should stay double quotes";
  good $Policy, 'my $ctrl = "\cA"',
    "Double quotes with only control-A escape should stay double quotes";
  good $Policy, 'my $ctrl = "\c@"',
    "Double quotes with only control-@ escape should stay double quotes";

  # Named Unicode
  good $Policy, 'my $named = "\N{LATIN SMALL LETTER A}"',
    "Double quotes with only named unicode should stay double quotes";
  good $Policy, 'my $named = "\N{U+263A}"',
    "Double quotes with only unicode codepoint should stay double quotes";
};

subtest "String modification escape sequences" => sub {
  # Test escape sequences that modify how subsequent characters are interpreted
  # These are not in the current regex pattern but should be tested

  # Case modification escapes
  good $Policy, 'my $lower = "\lHELLO"',
    "Double quotes with \\l (lowercase next char) should stay double quotes";
  good $Policy, 'my $upper = "\uhello"',
    "Double quotes with \\u (uppercase next char) should stay double quotes";
  good $Policy, 'my $lower_all = "\LHELLO WORLD\E"',
    "Double quotes with \\L...\\E (lowercase range) should stay double quotes";
  good $Policy, 'my $upper_all = "\Uhello world\E"',
    "Double quotes with \\U...\\E (uppercase range) should stay double quotes";

  # Quote meta escapes
  good $Policy, 'my $quoted = "\Q[special].chars\E"',
    "Double quotes with \\Q...\\E (quote meta) should stay double quotes";

  # Only escape sequences
  good $Policy, 'my $lower_only = "\l"',
    "Double quotes with only \\l escape should stay double quotes";
  good $Policy, 'my $upper_only = "\u"',
    "Double quotes with only \\u escape should stay double quotes";
  good $Policy, 'my $quote_only = "\Q"',
    "Double quotes with only \\Q escape should stay double quotes";
  good $Policy, 'my $end_only = "\E"',
    "Double quotes with only \\E escape should stay double quotes";
};

subtest "Incomplete and backslash escape sequences" => sub {
  # Test incomplete or malformed escape sequences

  # Incomplete hex escapes
  good $Policy, 'my $incomplete = "\x"',
    "Double quotes with incomplete \\x escape should stay double quotes";
  good $Policy, 'my $incomplete = "\x{"',
    "Double quotes with incomplete \\x{ escape should stay double quotes";
  good $Policy, 'my $incomplete = "\x{}"',
    "Double quotes with empty \\x{} escape should stay double quotes";

  # Incomplete octal escapes
  good $Policy, 'my $incomplete = "\o{"',
    "Double quotes with incomplete \\o{ escape should stay double quotes";
  good $Policy, 'my $incomplete = "\o{}"',
    "Double quotes with empty \\o{} escape should stay double quotes";

  # Incomplete named escapes
  good $Policy, 'my $incomplete = "\N{"',
    "Double quotes with incomplete \\N{ escape should stay double quotes";
  good $Policy, 'my $incomplete = "\N{}"',
    "Double quotes with empty \\N{} escape should stay double quotes";

  # Backslash at end of string
  bad $Policy, 'my $trailing = "\\"', "use ''",
    "Double quotes with only escaped backslash should use single quotes";
  bad $Policy, 'my $trailing = "text\\"', "use ''",
    "Double quotes with trailing escaped backslash should use single quotes";

  # Multiple consecutive backslashes
  bad $Policy, 'my $multiple = "\\\\"', "use ''",
    "Double quotes with multiple escaped backslashes should use single quotes";
  bad $Policy, 'my $multiple = "\\\\\\\\"', "use ''",
    "Double quotes with many escaped backslashes should use single quotes";
};

subtest "Mixed escape sequences" => sub {
  # Test strings containing multiple different escape sequences

  good $Policy, 'my $mixed = "\n\t"',
    "Double quotes with newline and tab should stay double quotes";
  good $Policy, 'my $mixed = "\r\n"',
    "Double quotes with CRLF should stay double quotes";
  good $Policy, 'my $mixed = "\x1b\033"',
    "Double quotes with hex and octal escapes should stay double quotes";
  good $Policy, 'my $mixed = "\t\x09"',
    "Double quotes with tab char and hex tab should stay double quotes";
  good $Policy, 'my $mixed = "\N{U+263A}\x{263A}"',
    "Double quotes with named and hex unicode should stay double quotes";
  good $Policy, 'my $mixed = "\a\b\e\f\n\r\t"',
    "Double quotes with all single char escapes should stay double quotes";
};

subtest "Case variations in hex escapes" => sub {
  # Test that hex escapes work with different case combinations

  good $Policy, 'my $hex = "\xAB"',
    "Double quotes with uppercase hex escape should stay double quotes";
  good $Policy, 'my $hex = "\xab"',
    "Double quotes with lowercase hex escape should stay double quotes";
  good $Policy, 'my $hex = "\xAb"',
    "Double quotes with mixed case hex escape should stay double quotes";
  good $Policy, 'my $hex = "\x{AbCd}"',
    "Double quotes with mixed case unicode hex should stay double quotes";
  good $Policy, 'my $hex = "\x{ABCD}"',
    "Double quotes with uppercase unicode hex should stay double quotes";
  good $Policy, 'my $hex = "\x{abcd}"',
    "Double quotes with lowercase unicode hex should stay double quotes";
};

subtest "Strings with conflicting quoting requirements" => sub {
  # Test strings that contain both content that would suggest single quotes
  # AND escape sequences that require double quotes. The escape sequences
  # should take precedence, keeping the string in double quotes.

  # Double quotes with escape sequences should stay double quotes even if
  # they contain content that would normally suggest single quotes
  good $Policy, 'my $mixed = "\"\n"',
    "Double quotes with quote and newline should stay double quotes";
  good $Policy, q(my $mixed = "Don't\t"),
    "Double quotes with apostrophe and tab should stay double quotes";
  good $Policy, q(my $mixed = "Can't\r"),
    "Double quotes with apostrophe and CR should stay double quotes";

  # Test with various single character escapes mixed with quote content
  good $Policy, 'my $mixed = "Quote: \"Hello\"\n"',
    "Double quotes with quotes and newline should stay double quotes";
  good $Policy, q(my $mixed = "Path: 'C:\\Program Files'\t"),
    "Double quotes with single quotes and tab should stay double quotes";
  good $Policy, 'my $mixed = "Alert!\aEnd"',
    "Double quotes with content and bell should stay double quotes";

  # Test with hex/octal escapes and quote content
  good $Policy, q(my $mixed = "Color: 'red'\x1b[0m"),
    "Double quotes with quotes and hex escape should stay double quotes";
  good $Policy, 'my $mixed = "Bell\033sound"',
    "Double quotes with content and octal escape should stay double quotes";
  good $Policy, 'my $mixed = "Unicode\x{263A}smiley"',
    "Double quotes with content and unicode should stay double quotes";

  # Test with control and named escapes mixed with content
  good $Policy, 'my $mixed = "Control\c[sequence"',
    "Double quotes with content and control escape should stay double quotes";
  good $Policy, 'my $mixed = "Named\N{SMILEY}char"',
    "Double quotes with content and named unicode should stay double quotes";

  # Test with string modification escapes and quote content
  good $Policy, q(my $mixed = "Make 'this'\lLOWER"),
    "Double quotes with quotes and lowercase escape should stay double quotes";
  good $Policy, q(my $mixed = "Make 'this'\upper"),
    "Double quotes with quotes and uppercase escape should stay double quotes";
  good $Policy, 'my $mixed = "Quote\Q[special]\Echars"',
    "Double quotes with content and quote meta should stay double quotes";

  # Test with backslash escapes and quote content
  good $Policy, q(my $mixed = "Path 'C:\\' backslash"),
    "Double quotes with quotes and backslash should stay double quotes";
  good $Policy, 'my $mixed = "Multiple\\\\backslashes"',
    "Double quotes with content and multiple backslashes should stay "
    . "double quotes";

  # Test edge case: only quote and escape sequence
  good $Policy, q(my $minimal = "'\n"),
    "Double quotes with only quote and newline should stay double quotes";
  good $Policy, 'my $minimal = "\"\t"',
    "Double quotes with only escaped quote and tab should stay double quotes";
};

done_testing;
