use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/pod2markdown',
    'lib/Pod/Markdown.pm',
    'lib/Pod/Perldoc/ToMarkdown.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/back-compat.t',
    't/basic.t',
    't/codes.t',
    't/encoding.t',
    't/entities.t',
    't/escape.t',
    't/formats.t',
    't/lib/MarkdownTests.pm',
    't/links.t',
    't/lists.t',
    't/meta.t',
    't/misc.t',
    't/nested.t',
    't/new.t',
    't/perldoc.t',
    't/pod2markdown.t',
    't/verbatim.t'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;
