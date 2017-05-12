use strict;
use warnings;
use Test::More;

use Statistics::Swoop;

{
    my @list = (qw/1 2 3 4 5/);
    my $ss = Statistics::Swoop->new(\@list);
    my $expect = +{
        count => 5,
        max   => 5,
        min   => 1,
        range => 4,
        sum   => 15,
        avg   => 3,
    };
    is_deeply $ss->result, $expect, 'result';
}

done_testing;
