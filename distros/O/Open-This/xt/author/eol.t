use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Open/This.pm',
    'script/ot',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/ansible.t',
    't/bin/date',
    't/git.t',
    't/github.t',
    't/kate.t',
    't/lib/Foo/Bar.pm',
    't/lib/Foo/Require.pm',
    't/lib/HTTP/FakeTestClass.pm',
    't/nano.t',
    't/open-this.t',
    't/ot.t',
    't/other-lib/Foo/Baz.pm',
    't/require.t',
    't/test-data/file',
    't/test-data/file with spaces',
    't/test-data/file-with-numbers-0.000020.txt',
    't/test-data/foo/bar/baz.html.ep',
    't/vim.t',
    't/which.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
