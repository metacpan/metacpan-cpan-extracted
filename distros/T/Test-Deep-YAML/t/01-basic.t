use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

binmode $_, ':encoding(UTF-8)' foreach map { Test::Builder->new->$_ } qw(output failure_output);

use Test::Deep::YAML;
use utf8;

use lib 't/lib';
use Util;

my @tests = (
    'invalid YAML' => {
        got => { foo => "--\n" },
        exp => { foo => yaml('') },
        ok => 0,
        diag => qr/^YAML Error: Expected separator '---'/,
    },

    'no match (top level, key)' => {
        got => "---\nboo: bar\n",
        exp => yaml({ foo => 'bar' }),
        ok => 0,
        diag => do {
            my ($ok, $diag) = cmp_diag({ boo => 'bar' }, { foo => 'bar' });
            $diag;
        },
    },
    'no match (top level, value)' => {
        got => "---\nfoo: baz\n",
        exp => yaml({ foo => 'bar' }),
        ok => 0,
        diag => do {
            my ($ok, $diag) = cmp_diag({ foo => 'baz' }, { foo => 'bar' });
            $diag;
        },
    },

    'no match (deeper, key)' => {
        got => "---\nfoo:\n  qux: baz\n",
        exp => yaml({ foo => { bar => 'baz' } }),
        ok => 0,
        diag => do {
            my ($ok, $diag) = cmp_diag(
                { foo => { qux => 'baz' } },
                { foo => { bar => 'baz' } },
            );
            $diag;
        },
    },
    'no match (deeper, value)' => {
        got => "---\nfoo:\n  bar: qux\n",
        exp => yaml({ foo => { bar => 'baz' } }),
        ok => 0,
        diag => do {
            my ($ok, $diag) = cmp_diag(
                { foo => { bar => 'qux' } },
                { foo => { bar => 'baz' } },
            );
            $diag;
        },
    },
    'no match (deeper, nested plugin)' => {
        got => "---\nfoo:\n  bar: qux\n",
        exp => yaml(Test::Deep::code(sub { (0, 'oh noes') })),
        ok => 0,
        diag => do {
            my ($ok, $diag) = cmp_diag(
                "---\nfoo:\n  bar: qux\n",
                Test::Deep::code(sub { (0, 'oh noes') }),
            );
            $diag;
        },
    },

    'match' => {
        got => "---\nfoo: bar\n",
        exp => yaml({ foo => 'bar' }),
        ok => 1,
    },
    'deep match' => {
        got => { string => "---\nfoo: bar\n" },
        exp => { string => yaml({ foo => 'bar' }) },
        ok => 1,
    },

    'match, UTF-8 encoded' => {
        got => "--- \nauthor: \"Ævar Arnfjörð Bjarmason <avar\@cpan.org>\"\n",
        exp => yaml({ author => 'Ævar Arnfjörð Bjarmason <avar@cpan.org>' }),
        ok => 1,
    },
);

while (my ($test_name, $test) = (shift(@tests), shift(@tests)))
{
    last if not $test_name;

    subtest $test_name => test_plugin(@{$test}{qw(got exp ok diag)});

    # for author testing only
    BAIL_OUT('oops') if -e '.git' and not Test::Builder->new->is_passing;
}

done_testing;
