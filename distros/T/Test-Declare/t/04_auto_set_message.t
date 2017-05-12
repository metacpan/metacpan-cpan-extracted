use strict;
use warnings;
use Test::Tester tests => 6;
use Test::Declare;

check_test(
    sub {
        describe 'can i set a default message?' => run {
            test 'namename' => run {
                local $Test::Builder::Level = 4; # todo
                is 'foo', 'foo';
            };
        };
    },
    {
        ok => 1,
        name => 'namename',
    },
);

