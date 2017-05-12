use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep::UnorderedPairs;

use lib 't/lib';
use Util;

my @tests = (
    'repeated key, missing a key' => {
        got => [ foo => 1, foo => 2 ],
        exp => tuples(foo => 2, bar => 1),
        ok => 0,
        diag => "Comparing keys of \$data\nMissing: 'bar'\nExtra: 'foo'\n",
    },
    'repeated key, extra key' => {
        got => [ foo => 1, bar => 2 ],
        exp => tuples(bar => 2, bar => 1),
        ok => 0,
        diag => "Comparing keys of \$data\nMissing: 'bar'\nExtra: 'foo'\n",
    },

    'repeated key, keys ok, value wrong' => {
        got => [ foo => 1, foo => 3, bar => 3 ],
        exp => tuples(bar => 3, foo => 1, foo => 2),
        ok => 0,
        diag => qr/^Compared \$data->\[3\]\n\s+got : '3'\nexpect : '2'\n$/,
    },
    'repeated key ok' => {
        got => [ foo => 1, foo => 2, bar => 3 ],
        exp => tuples(bar => 3, foo => 1, foo => 2),
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
