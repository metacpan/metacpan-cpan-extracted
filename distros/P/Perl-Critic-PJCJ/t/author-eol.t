
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
    'lib/Perl/Critic/Policy/CodeLayout/ProhibitLongLines.pm',
    'lib/Perl/Critic/Policy/ValuesAndExpressions/RequireConsistentQuoting.pm',
    'lib/Perl/Critic/Utils/SourceLocation.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/CodeLayout/ProhibitLongLines/basic.t',
    't/CodeLayout/ProhibitLongLines/configuration.t',
    't/CodeLayout/ProhibitLongLines/line_number_reporting.t',
    't/Utils/SourceLocation/basic.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/basic.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/delimiter_optimisation.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/double_quotes.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/escape_sequences.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/messages.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/newlines.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/quote_like_operators.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/quote_operators.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/simple_quote_operators.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/single_quotes.t',
    't/ValuesAndExpressions/RequireConsistentQuoting/use_statement_quote_types.t',
    't/lib/ViolationFinder.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
