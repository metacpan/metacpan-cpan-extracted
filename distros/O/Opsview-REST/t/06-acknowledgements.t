
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
        url  => '/acknowledge',
    },
    {
        args => [ host => 'hostA' ],
        url  => '/acknowledge?host=hostA',
    },
    {
        args => [ host => [qw/ hostA hostB /] ],
        url  => '/acknowledge?host=hostA&host=hostB',
    },
    {
        args => [
            host    => [qw/ hostA hostB /],
            keyword => [qw/ abcde efghi /],
        ],
        url  => '/acknowledge?keyword=abcde&keyword=efghi&host=hostA&host=hostB',
    },
);

plan tests => scalar @tests + 2;

require_ok 'Opsview::REST::Acknowledge';

test_urls('Opsview::REST::Acknowledge', @tests);

SKIP: {
    skip 'No $ENV{OPSVIEW_REST_TEST} defined', 1
        if (not defined $ENV{OPSVIEW_REST_TEST});

    my $ops = get_opsview();
    lives_ok { $ops->acknowledge_list } "Call to 'acknowledge_list' didn't die";

};

