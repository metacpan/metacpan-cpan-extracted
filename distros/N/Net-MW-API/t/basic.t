use strict;
use Test::More tests => 5;
use Net::MW::API;

# TODO
# I have test it use my own api key.
# it seems hard to test in this situation.
# there is a small test file in examples dir
is(Net::MW::API::_subdir("bixgrat"), 'bix', 'bix');
is(Net::MW::API::_subdir("gggrat"), 'gg', 'gg');
is(Net::MW::API::_subdir("1grat"), '1', 'begin with number');
is(Net::MW::API::_subdir("1"), '1', 'only number');
is(Net::MW::API::_subdir("grat"), 'g', 'default');



