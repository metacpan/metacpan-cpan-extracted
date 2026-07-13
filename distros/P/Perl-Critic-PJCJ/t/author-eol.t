
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Perl/Critic/PJCJ.pm',
    'lib/Perl/Critic/PJCJ/Fixer.pm',
    'lib/Perl/Critic/PJCJ/Violation.pm',
    'lib/Perl/Critic/Policy/CodeLayout/ProhibitLongLines.pm',
    'lib/Perl/Critic/Policy/ValuesAndExpressions/RequireConsistentQuoting.pm',
    'lib/Perl/Critic/Utils/SourceLocation.pm',
    'script/perl-quote-fix',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/CodeLayout/ProhibitLongLines/basic.t',
    't/CodeLayout/ProhibitLongLines/character_length.t',
    't/CodeLayout/ProhibitLongLines/configuration.t',
    't/CodeLayout/ProhibitLongLines/gitattributes.t',
    't/CodeLayout/ProhibitLongLines/line_number_reporting.t',
    't/Fixer/declined_fixes.t',
    't/Fixer/delimiters.t',
    't/Fixer/double_to_single.t',
    't/Fixer/edge_cases.t',
    't/Fixer/fixpoint.t',
    't/Fixer/operators_to_plain.t',
    't/Fixer/qw_words.t',
    't/Fixer/script.t',
    't/Fixer/single_to_double.t',
    't/Fixer/use_statements.t',
    't/Utils/SourceLocation/basic.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/basic.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/delimiter_optimisation.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/double_quotes.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/escape_sequences.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/fix_data.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/messages.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/newlines.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/quote_like_operators.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/quote_operators.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/simple_quote_operators.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/single_quotes.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/unterminated.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/use_statement_quote_types.t',
    't/commit-msg-hook.t',
    't/git-hook.t',
    't/lib/FakePolicy.pm',
    't/lib/ViolationFinder.pm',
    't/perl-hook.t',
    't/prepare-commit-msg-hook.t',
    't/synopsis_activation.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
