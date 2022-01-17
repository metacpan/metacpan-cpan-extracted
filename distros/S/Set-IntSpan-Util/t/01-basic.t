#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Set::IntSpan::Util qw(intspans2str);

subtest intspans2str => sub {
    is(intspans2str(1), '1');
    is(intspans2str(1,2,3,4,5), '1-5');
    is(intspans2str(1,3,4,6,8), '1, 3-4, 6, 8');

    subtest "option: dash" => sub {
        is(intspans2str({dash=>"="}, 1,3,4,6,8), '1, 3=4, 6, 8');
    };

    subtest "option: comma" => sub {
        is(intspans2str({comma=>";"}, 1,3,4,6,8), '1;3-4;6;8');
    };
};

DONE_TESTING:
done_testing;
