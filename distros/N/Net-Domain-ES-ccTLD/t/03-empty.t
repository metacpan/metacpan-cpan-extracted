#!perl -T

use Test::More tests => 1;
use Net::Domain::ES::ccTLD;

eval {
    find_name_by_cctld();
    1;
} or do {
    ok(defined $@, "find_name_by_cctld() needs an argument");
};
