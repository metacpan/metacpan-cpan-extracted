
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Opsview::REST::TestUtils;

use Test::More;
use Test::Exception;

my @tests = (
    {
        args => [ ],
        url  => '/event',
    },
    {
        args => [ host => 'hostA' ],
        url  => '/event?host=hostA',
    },
    {
        args => [ host => [qw/ hostA hostB /] ],
        url  => '/event?host=hostA&host=hostB',
    },
    {
        args => [
            host    => [qw/ hostA hostB /],
            keyword => [qw/ abcde efghi /],
        ],
        url  => '/event?keyword=abcde&keyword=efghi&host=hostA&host=hostB',
    },
);

plan tests => scalar @tests + 2;

require_ok 'Opsview::REST::Event';

test_urls('Opsview::REST::Event', @tests);

SKIP: {
    skip 'No $ENV{OPSVIEW_REST_TEST} defined', 1
        if (not defined $ENV{OPSVIEW_REST_TEST});

    my $ops = get_opsview();
    lives_ok { $ops->events } "Call to 'events' didn't die";

};

