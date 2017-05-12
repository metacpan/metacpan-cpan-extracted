
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
        url  => '/recheck',
    },
    {
        args => [ host => 'hostA' ],
        url  => '/recheck?host=hostA',
    },
    {
        args => [ host => [qw/ hostA hostB /] ],
        url  => '/recheck?host=hostA&host=hostB',
    },
    {
        args => [
            host    => [qw/ hostA hostB /],
            keyword => [qw/ abcde efghi /],
        ],
        url  => '/recheck?keyword=abcde&keyword=efghi&host=hostA&host=hostB',
    },
);

require_ok 'Opsview::REST::Recheck';

test_urls('Opsview::REST::Recheck', @tests);

SKIP: {
    skip 'No $ENV{OPSVIEW_REST_TEST} defined', 1
        if (not defined $ENV{OPSVIEW_REST_TEST});

    my $ops = get_opsview();
    my $res;

    lives_ok {
        $res = $ops->recheck(host => 'opsview');
    } "Call to recheck didn't die";

    ok(defined $res->{summary}, 'Got a summary in the response');
    is($res->{summary}->{num_hosts}, 1, 'One host rechecked');
};

done_testing;
