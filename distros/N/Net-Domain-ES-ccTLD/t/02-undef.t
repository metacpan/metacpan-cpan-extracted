#!perl -T

use utf8;
use Test::More tests => 1;
use Net::Domain::ES::ccTLD;

is( 
    find_name_by_cctld('xx'),
    undef,
    "not finding out 'xx' is cool .."
);
