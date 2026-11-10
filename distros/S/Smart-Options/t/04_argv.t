use strict;
use Test::More;

use Smart::Options;

subtest 'use @ARGV' => sub {
    local @ARGV = qw(-a 1 -b 2 -- -c 3 -d 4);

    is argv->{a}, 1;
    is argv->{b}, 2;
    is_deeply argv->{_}, ['-c', '3', '-d', '4'];
};

done_testing;
