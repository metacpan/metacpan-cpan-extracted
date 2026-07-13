#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;
use feature "signatures";
use experimental "signatures";
use lib qw( lib t/lib );

use Test2::V0 qw( done_testing subtest );

use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting qw(
  desc_double
  desc_remove_parens
  desc_use_qw
);
use ViolationFinder qw( bad count_violations good );

my $Policy
  = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;

subtest "Use statement argument rules" => sub {
  # Module with no arguments - OK
  good $Policy, "use Foo",    "use with no arguments is fine";
  good $Policy, "use Foo ()", "use with empty parens is fine";

  # Module with one argument - should use qw()
  bad $Policy, 'use Foo "arg1"', desc_use_qw,
    "use with one double-quoted argument should use qw()";
  bad $Policy, "use Foo 'arg1'", desc_use_qw,
    "use with one single-quoted argument should use qw()";
  good $Policy, "use Foo qw(arg1)", "use with one qw() argument is fine";

  # Module with multiple arguments - all simple strings should use qw()
  bad $Policy, 'use Foo "arg1", "arg2"', desc_use_qw,
    "use with multiple double-quoted arguments should use qw()";
  bad $Policy, "use Foo 'arg1', 'arg2'", desc_use_qw,
    "use with multiple single-quoted arguments should use qw()";
  bad $Policy, "use Foo ('arg1', 'arg2')", desc_use_qw,
    "use with multiple single-quoted arguments in parens should use qw()";
  bad $Policy, 'use Foo "arg1", "arg2", "arg3"', desc_use_qw,
    "use with three double-quoted arguments should use qw()";

  # Mixed arguments - should use qw()
  bad $Policy, "use Foo qw(arg1), 'arg2'", desc_use_qw,
    "mixed qw() and quotes should use qw() for all";
  bad $Policy, "use Foo 'arg1', qw(arg2)", desc_use_qw,
    "mixed quotes and qw() should use qw() for all";

  # Good cases with multiple arguments
  good $Policy, "use Foo qw(arg1 arg2)",
    "multiple arguments with qw() is correct";
  good $Policy, "use Foo qw(arg1 arg2 arg3)",
    "three arguments with qw() is correct";
  bad $Policy, "use Foo qw[arg1 arg2]", desc_use_qw,
    "qw[] should use qw() with parentheses only";

  # Other statement types should not be checked
  good $Policy, "require Foo", "require statements are not checked";
};

subtest "'no' statement argument rules" => sub {
  # Module with no arguments - OK
  good $Policy, "no warnings",    "no with no arguments is fine";
  good $Policy, "no warnings ()", "no with empty parens is fine";

  # Pragma with one argument - quotes allowed, normal rules apply
  good $Policy, 'no warnings "arg1"',
    "no pragma with one double-quoted argument is fine";
  bad $Policy, "no warnings 'arg1'", desc_double,
    "no pragma with single-quoted argument should use double quotes";
  good $Policy, "no warnings qw(arg1)", "no with one qw() argument is fine";

  # Pragma with multiple arguments - all simple strings should use qw()
  bad $Policy, 'no warnings "arg1", "arg2"', desc_use_qw,
    "no with multiple double-quoted arguments should use qw()";
  bad $Policy, "no warnings 'arg1', 'arg2'", desc_use_qw,
    "no warnings with multiple single-quoted arguments should use qw()";

  # Good cases with multiple arguments
  good $Policy, "no warnings qw(arg1 arg2)",
    "multiple arguments with qw() is correct";

  # Mixed arguments - should use qw()
  bad $Policy, "no warnings qw(arg1), 'arg2'", desc_use_qw,
    "mixed qw() and quotes should use qw() for all";

  # Interpolation should prevent qw() suggestion
  good $Policy, 'no warnings "$x/d1", "$x/d2"',
    "double quotes with interpolation should not suggest qw()";
  good $Policy, q(no warnings '$x/d1', '$x/d2'),
    'single quotes with \$ characters should not suggest qw()';

  # Mixed case - interpolation prevents qw() suggestion
  good $Policy, 'no warnings "$x/d1", "static"',
    "mixed interpolation and static string with double quotes";
  bad $Policy, q(no warnings "$x/d1", 'static'), desc_double,
    "single quotes for simple string should suggest double quotes";
};

subtest "q() and qq() operators in use statements should use qw()" => sub {
  # With the new rules, q() and qq() operators should trigger use qw()
  # violations

  # Test q() quotes inside use statements - should use qw()
  bad $Policy, "use Foo q(simple)", desc_use_qw,
    "q() in use statements should use qw()";
  bad $Policy, "use Foo q{simple}", desc_use_qw,
    "q{} in use statements should use qw()";
  bad $Policy, "use Foo q[simple]", desc_use_qw,
    "q[] in use statements should use qw()";
  bad $Policy, "use Foo q<simple>", desc_use_qw,
    "q<> in use statements should use qw()";

  # Test qq() quotes inside use statements - should use qw()
  bad $Policy, "use Foo qq(simple)", desc_use_qw,
    "qq() in use statements should use qw()";
  bad $Policy, "use Foo qq{simple}", desc_use_qw,
    "qq{} in use statements should use qw()";
  bad $Policy, "use Foo qq[simple]", desc_use_qw,
    "qq[] in use statements should use qw()";
  bad $Policy, "use Foo qq<simple>", desc_use_qw,
    "qq<> in use statements should use qw()";
};

subtest "Use statements with multiple quote types" => sub {
  # Test multiple arguments to trigger the use statement multiple argument rule
  bad $Policy, "use Foo q(arg1), q(arg2)", desc_use_qw,
    "multiple q() arguments trigger use statement rule";
  bad $Policy, "use Foo qq(arg1), qq(arg2)", desc_use_qw,
    "multiple qq() arguments trigger use statement rule";

  # Mixed quote types
  bad $Policy, 'use Foo q(arg1), "arg2"', desc_use_qw,
    "mixed q() and double quotes trigger use statement rule";
  bad $Policy, 'use Foo qq(arg1), "arg2"', desc_use_qw,
    "mixed qq() and double quotes trigger use statement rule";
};

subtest "Edge cases for coverage" => sub {
  # Test semicolon handling - covers the semicolon branch in
  # _extract_use_arguments
  bad $Policy, 'use Foo "arg"; # with semicolon', desc_use_qw,
    "use statement with semicolon should use qw() for simple string";

  # Test require and no statements to ensure they don't trigger use statement
  # logic
  bad $Policy, "require q(file.pl)", desc_double,
    "require with q() is not processed by use statement logic";
  bad $Policy, "no warnings qq(experimental)", desc_double,
    "no pragma qq() with single arg should use double quotes";
};

subtest "Use statement structure parsing coverage" => sub {
  # With the new behaviour, multiple double-quoted strings should use qw()
  bad $Policy, 'use Foo "arg1", "arg2";', desc_use_qw,
    "use statement with semicolon and multiple double-quoted args "
    . "should use qw()";

  bad $Policy, 'use Foo "arg1", "arg2", "arg3"', desc_use_qw,
    "three double-quoted string arguments should use qw()";
};

subtest
  "Use statements with hash-style arguments (=>) should have no parentheses" =>
  sub {
    # Test the Data::Printer example - should prefer no parentheses
    bad $Policy, <<~'EOT', desc_remove_parens,
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

    bad $Policy, 'use Foo ("simple", key => "value")', desc_remove_parens,
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
  bad $Policy, 'use Module ($VERSION)', desc_remove_parens,
    "variable argument with parentheses should remove parentheses";
  bad $Policy, 'use Module ($DEBUG ? "verbose" : "quiet")',
    desc_remove_parens,
    "conditional expression with parentheses should remove parentheses";
  bad $Policy, 'use Module ({ config => "hash" })', desc_remove_parens,
    "hash reference with parentheses should remove parentheses";
};

subtest "Call parentheses are not statement parentheses" => sub {
  good $Policy, 'use lib File::Spec->catdir($dir, "lib");',
    "method call parentheses do not count as statement parentheses";
  good $Policy, "use constant N => calc();",
    "function call parentheses do not count as statement parentheses";
  good $Policy, "use constant PI => atan2(1, 1) * 4;",
    "call parentheses inside an expression are left alone";
  bad $Policy, 'use Foo 1.23 ($x)', desc_remove_parens,
    "a wrapper list after a version number is still statement-level";
};

subtest "Expressions among use arguments are complex" => sub {
  good $Policy, 'use lib dirname(__FILE__) . "/lib";',
    "a concatenation of a call and a string is not an import list";
  good $Policy, 'use Foo "a" . "b";',
    "concatenated strings are an expression, not an import list";
  good $Policy, 'use Foo bar, "baz";',
    "a plain bareword is not a qw-able word";
  bad $Policy, 'use parent -norequire, "Foo"', desc_use_qw,
    "a leading-hyphen bareword still merges into qw()";
};

subtest "qw() is only suggested for representable words" => sub {
  good $Policy, 'use Foo "hello world"', "a space cannot survive qw";
  good $Policy, 'use Foo ""',            "an empty string would be dropped";
  good $Policy, 'use Foo "a(b"',
    "an unbalanced parenthesis would break qw( )";
  good $Policy, "use Foo 'a b', 'c'", "one bad word poisons the list";
  good $Policy, 'use Foo qw( a ), "b c"',
    "mixed qw and unrepresentable strings are left alone";
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
  good $Policy, 'use lib ( "$HOME/perl" );',
    "single interpolating pragma argument in parens is exempt";

  # Single quotes with $ or @ should not suggest qw() because it would change
  # meaning
  good $Policy, q(use lib '$x/d1', '$x/d2'),
    'single quotes with \$ characters should not suggest qw()';

  # Mixed case - interpolation in one, not in other
  # The non-interpolating string should follow normal rules
  good $Policy, 'use lib "$x/d1", "static"',
    "mixed interpolation and static string with double quotes";
  bad $Policy, q(use lib "$x/d1", 'static'), desc_double,
    "single quotes for simple string should suggest double quotes";

  # More mixed cases
  bad $Policy, q(use lib "$HOME/perl", '/usr/lib'), desc_double,
    "single quotes for /usr/lib should suggest double quotes";
  good $Policy, 'use lib "$HOME/perl", "/usr/lib"',
    "double quotes for both when one needs interpolation";

  # qq{} with interpolation should not suggest qw(), but should follow normal
  # rules
  bad $Policy, 'use lib qq{$HOME/perl}, "$HOME/lib"', desc_double,
    "qq{} should suggest double quotes per normal rules";
};

subtest "Simple strings in parentheses should use qw()" => sub {
  # These were previously good but should now be bad
  bad $Policy, 'use Foo ("arg1", "arg2")', desc_use_qw,
    "simple strings in parentheses should use qw()";

  bad $Policy, 'use Foo ("single")', desc_use_qw,
    "single string in parentheses should use qw()";

  bad $Policy, 'use Foo ("arg1"), "arg2"', desc_use_qw,
    "mixed parentheses and bare simple strings should use qw()";
};

subtest "Degenerate and version-only use statements" => sub {
  count_violations $Policy, "use", 0,
    "a bare use statement produces no violations";
  good $Policy, "use Baz 1.23", "a lone version number is exempt";
  bad $Policy, 'use POSIX 1.23 "floor";', desc_use_qw,
    "version plus import list uses qw for the strings";
  bad $Policy, 'use POSIX 1.23 "floor", "ceil"', desc_use_qw,
    "version plus several imports uses qw for the strings";
  good $Policy, "use POSIX 1.23 qw( floor )", "the target form is accepted";
  good $Policy, 'use Foo "a", 1.23',
    "a number inside the import list is complex";
  bad $Policy, 'use Foo (1.23, "a")', desc_remove_parens,
    "a parenthesised list holding a number is complex";
};

subtest "Pragma single-argument quoting" => sub {
  # Pragmas (all-lowercase module names) with a single argument allow quotes
  good $Policy, 'use feature "class"',
    "pragma with single double-quoted argument is fine";
  good $Policy, 'use strict "refs"',
    "use strict with double-quoted argument is fine";
  good $Policy, 'no warnings "experimental"',
    "no pragma with double-quoted argument is fine";
  good $Policy, 'no warnings ( "experimental" )',
    "no pragma with parenthesised single argument is fine";
  good $Policy, "use feature qw(class)",
    "pragma with single qw() argument is still fine";
  good $Policy, 'use lib "/some/path"',
    "use lib with double-quoted path is fine";
  good $Policy, 'use parent "Foo::Bar"',
    "use parent with double-quoted module is fine";

  # Single quotes should still get normal Rule 2 violation
  bad $Policy, "use feature 'class'", desc_double,
    "pragma with single-quoted argument should use double quotes";

  # Multiple arguments still require qw()
  bad $Policy, 'use feature "class", "say"', desc_use_qw,
    "pragma with multiple arguments should use qw()";

  # Non-pragmas (uppercase) still require qw()
  bad $Policy, 'use Foo "bar"', desc_use_qw,
    "non-pragma with single argument should use qw()";

  # Digits count as pragma characters, matching PPI
  good $Policy, 'use foo1 "x"', "digits still count as pragma characters";

  # A lowercase module with an underscore is not a pragma to PPI
  bad $Policy, 'use foo_bar "x";', desc_use_qw,
    "lowercase module with an underscore is not a pragma";
  bad $Policy, "use foo_bar 'x';", desc_use_qw,
    "underscore module gets the statement rule, not the string rule";
};

subtest "use statement verdict is per document" => sub {
  # The one shared $Policy judges each document afresh, with no verdict
  # carried over from an earlier one
  bad $Policy, 'use Foo "one", "two";', desc_use_qw,
    "strings inside a plain use are exempt, statement flagged";
  bad $Policy, q(use Foo 'one', "$var";), desc_double,
    "with interpolation the single-quoted argument is flagged";
  bad $Policy, 'use Foo "one", "two";', desc_use_qw,
    "a later document is judged afresh";
};

done_testing;
