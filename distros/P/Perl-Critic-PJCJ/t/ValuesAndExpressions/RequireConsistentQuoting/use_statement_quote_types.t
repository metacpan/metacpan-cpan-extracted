#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing subtest );
use feature      qw( signatures );
use experimental qw( signatures );

# Test to exercise uncovered branches in quote checking within use statements
use lib qw( lib t/lib );
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting ();
use ViolationFinder qw( bad good );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "Use statement argument rules" => sub {
  # Module with no arguments - OK
  good $Policy, "use Foo",    "use with no arguments is fine";
  good $Policy, "use Foo ()", "use with empty parens is fine";

  # Module with one argument - should use qw()
  bad $Policy, 'use Foo "arg1"', "use qw()",
    "use with one double-quoted argument should use qw()";
  bad $Policy, "use Foo 'arg1'", "use qw()",
    "use with one single-quoted argument should use qw()";
  good $Policy, "use Foo qw(arg1)", "use with one qw() argument is fine";

  # Module with multiple arguments - all simple strings should use qw()
  bad $Policy, 'use Foo "arg1", "arg2"', "use qw()",
    "use with multiple double-quoted arguments should use qw()";
  bad $Policy, "use Foo 'arg1', 'arg2'", "use qw()",
    "use with multiple single-quoted arguments should use qw()";
  bad $Policy, "use Foo ('arg1', 'arg2')", "use qw()",
    "use with multiple single-quoted arguments in parens should use qw()";
  bad $Policy, 'use Foo "arg1", "arg2", "arg3"', "use qw()",
    "use with three double-quoted arguments should use qw()";

  # Mixed arguments - should use qw()
  bad $Policy, "use Foo qw(arg1), 'arg2'", "use qw()",
    "mixed qw() and quotes should use qw() for all";
  bad $Policy, "use Foo 'arg1', qw(arg2)", "use qw()",
    "mixed quotes and qw() should use qw() for all";

  # Good cases with multiple arguments
  good $Policy, "use Foo qw(arg1 arg2)",
    "multiple arguments with qw() is correct";
  good $Policy, "use Foo qw(arg1 arg2 arg3)",
    "three arguments with qw() is correct";
  bad $Policy, "use Foo qw[arg1 arg2]", "use qw()",
    "qw[] should use qw() with parentheses only";

  # Other statement types should not be checked
  good $Policy, "require Foo", "require statements are not checked";
};

subtest "'no' statement argument rules" => sub {
  # Module with no arguments - OK
  good $Policy, "no warnings",    "no with no arguments is fine";
  good $Policy, "no warnings ()", "no with empty parens is fine";

  # Module with one argument - should use qw()
  bad $Policy, 'no warnings "arg1"', "use qw()",
    "no with one double-quoted argument should use qw()";
  bad $Policy, "no warnings 'arg1'", "use qw()",
    "no with one single-quoted argument should use qw()";
  good $Policy, "no warnings qw(arg1)", "no with one qw() argument is fine";

  # Module with multiple arguments - all simple strings should use qw()
  bad $Policy, 'no warnings "arg1", "arg2"', "use qw()",
    "no with multiple double-quoted arguments should use qw()";
  bad $Policy, "no warnings 'arg1', 'arg2'", "use qw()",
    "no warnings with multiple single-quoted arguments should use qw()";

  # Good cases with multiple arguments
  good $Policy, "no warnings qw(arg1 arg2)",
    "multiple arguments with qw() is correct";

  # Mixed arguments - should use qw()
  bad $Policy, "no warnings qw(arg1), 'arg2'", "use qw()",
    "mixed qw() and quotes should use qw() for all";

  # No statements with interpolation should not suggest qw()
  good $Policy, 'no warnings "$x/d1", "$x/d2"',
    "double quotes with interpolation should not suggest qw()";
  good $Policy, q(no warnings '$x/d1', '$x/d2'),
    'single quotes with \$ characters should not suggest qw()';

  # Mixed case - interpolation prevents qw() suggestion
  good $Policy, 'no warnings "$x/d1", "static"',
    "mixed interpolation and static string with double quotes";
  bad $Policy, q(no warnings "$x/d1", 'static'), 'use ""',
    "single quotes for simple string should suggest double quotes";
};

subtest "q() and qq() operators in use statements should use qw()" => sub {
  # With the new rules, q() and qq() operators should trigger use qw()
  # violations

  # Test q() quotes inside use statements - should use qw()
  bad $Policy, "use Foo q(simple)", "use qw()",
    "q() in use statements should use qw()";
  bad $Policy, "use Foo q{simple}", "use qw()",
    "q{} in use statements should use qw()";
  bad $Policy, "use Foo q[simple]", "use qw()",
    "q[] in use statements should use qw()";
  bad $Policy, "use Foo q<simple>", "use qw()",
    "q<> in use statements should use qw()";

  # Test qq() quotes inside use statements - should use qw()
  bad $Policy, "use Foo qq(simple)", "use qw()",
    "qq() in use statements should use qw()";
  bad $Policy, "use Foo qq{simple}", "use qw()",
    "qq{} in use statements should use qw()";
  bad $Policy, "use Foo qq[simple]", "use qw()",
    "qq[] in use statements should use qw()";
  bad $Policy, "use Foo qq<simple>", "use qw()",
    "qq<> in use statements should use qw()";
};

subtest "Use statements with multiple quote types" => sub {
  # Test multiple arguments to trigger the use statement multiple argument rule
  bad $Policy, "use Foo q(arg1), q(arg2)", "use qw()",
    "multiple q() arguments trigger use statement rule";
  bad $Policy, "use Foo qq(arg1), qq(arg2)", "use qw()",
    "multiple qq() arguments trigger use statement rule";

  # Mixed quote types
  bad $Policy, 'use Foo q(arg1), "arg2"', "use qw()",
    "mixed q() and double quotes trigger use statement rule";
  bad $Policy, 'use Foo qq(arg1), "arg2"', "use qw()",
    "mixed qq() and single quotes trigger use statement rule";
};

subtest "Edge cases for coverage" => sub {
  # Test semicolon handling - covers the semicolon branch in
  # _extract_use_arguments
  bad $Policy, 'use Foo "arg"; # with semicolon', "use qw()",
    "use statement with semicolon should use qw() for simple string";

  # Test require and no statements to ensure they don't trigger use statement
  # logic
  bad $Policy, "require q(file.pl)", 'use ""',
    "require with q() is not processed by use statement logic";
  bad $Policy, "no warnings qq(experimental)", "use qw()",
    "no statement qq() is now processed by use statement logic";
};

subtest "Use statement structure parsing coverage" => sub {
  # With the new behavior, multiple double-quoted strings should use qw()
  bad $Policy, 'use Foo "arg1", "arg2";', "use qw()",
    "use statement with semicolon and multiple double-quoted args "
    . "should use qw()";

  bad $Policy, 'use Foo "arg1", "arg2", "arg3"', "use qw()",
    "three double-quoted string arguments should use qw()";
};

subtest
  "Use statements with hash-style arguments (=>) should have no parentheses" =>
  sub {
    # Test the Data::Printer example - should prefer no parentheses
    bad $Policy, <<~'EOT', "remove parentheses",
    use Data::Printer (
      deparse       => 0,
      show_unicode  => 1,
      print_escapes => 1,
      class => { expand => "all", parents => 0, show_methods => "none" },
      filters => $Data::Printer::VERSION >= 1 ?
        ["DB"] : { -external => ["DB"] }
    );
    EOT
    "complex use statement with parentheses should remove parentheses";

    good $Policy,
    <<~'EOT', "complex use statement without parentheses is correct";
  use Data::Printer
    deparse       => 0,
    show_unicode  => 1,
    print_escapes => 1,
    class         => { expand => "all", parents => 0, show_methods => "none" },
    filters => $Data::Printer::VERSION >= 1 ? ["DB"] : { -external => ["DB"] };
  EOT

    # Mixed => and simple strings should have no parentheses
    good $Policy, 'use Foo "simple", key => "value", "another"',
    "mixed simple strings and hash-style should have no parentheses";

    bad $Policy, 'use Foo ("simple", key => "value")', "remove parentheses",
    "mixed arguments with parentheses should remove parentheses";
  };

subtest "Complex expressions should have no parentheses" => sub {
  # Variables and expressions
  good $Policy, 'use Module $VERSION',
    "variable argument without parentheses is correct";
  good $Policy, 'use Module $DEBUG ? "verbose" : "quiet"',
    "conditional expression without parentheses is correct";
  good $Policy, 'use Module { config => "hash" }',
    "hash reference without parentheses is correct";

  # These should trigger violations for having parentheses
  bad $Policy, 'use Module ($VERSION)', "remove parentheses",
    "variable argument with parentheses should remove parentheses";
  bad $Policy, 'use Module ($DEBUG ? "verbose" : "quiet")',
    "remove parentheses",
    "conditional expression with parentheses should remove parentheses";
  bad $Policy, 'use Module ({ config => "hash" })', "remove parentheses",
    "hash reference with parentheses should remove parentheses";
};

subtest "Special cases should not trigger violations" => sub {
  # Version numbers
  good $Policy, "use Module 1.23",
    "numeric version should not trigger violation";
  good $Policy, "use Module v5.10.0",
    "v-string version should not trigger violation";

  # Already correct qw() usage
  good $Policy, "use Foo qw(arg1 arg2)",
    "correct qw() usage should not trigger violation";
};

subtest "Use statements with interpolation should not suggest qw()" => sub {
  # When strings need interpolation, they should follow normal string rules
  # not suggest qw()

  # These should be good - interpolation is needed
  good $Policy, 'use lib "$x/d1", "$x/d2"',
    "double quotes with interpolation should not suggest qw()";
  good $Policy, 'use lib "$HOME/perl", "$HOME/lib"',
    "multiple interpolations should not suggest qw()";

  # Single quotes with $ or @ should not suggest qw() because it would change
  # meaning
  good $Policy, q(use lib '$x/d1', '$x/d2'),
    'single quotes with \$ characters should not suggest qw()';

  # Mixed case - interpolation in one, not in other
  # The non-interpolating string should follow normal rules
  good $Policy, 'use lib "$x/d1", "static"',
    "mixed interpolation and static string with double quotes";
  bad $Policy, q(use lib "$x/d1", 'static'), 'use ""',
    "single quotes for simple string should suggest double quotes";

  # More mixed cases
  bad $Policy, q(use lib "$HOME/perl", '/usr/lib'), 'use ""',
    "single quotes for /usr/lib should suggest double quotes";
  good $Policy, 'use lib "$HOME/perl", "/usr/lib"',
    "double quotes for both when one needs interpolation";

  # qq{} with interpolation should not suggest qw(), but should follow normal
  # rules
  bad $Policy, 'use lib qq{$HOME/perl}, "$HOME/lib"', 'use ""',
    "qq{} should suggest double quotes per normal rules";
};

subtest "Simple strings in parentheses should use qw()" => sub {
  # These were previously good but should now be bad
  bad $Policy, 'use Foo ("arg1", "arg2")', "use qw()",
    "simple strings in parentheses should use qw()";

  bad $Policy, 'use Foo ("single")', "use qw()",
    "single string in parentheses should use qw()";

  bad $Policy, 'use Foo ("arg1"), "arg2"', "use qw()",
    "mixed parentheses and bare simple strings should use qw()";
};

done_testing;
