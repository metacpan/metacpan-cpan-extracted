use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
