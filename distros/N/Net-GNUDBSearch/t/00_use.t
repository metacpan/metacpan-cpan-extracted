use strict;
use warnings;
use Test::More;
use lib qw(lib ../lib);
plan(tests => 3);
#1
use_ok("Net::GNUDB::Cd");
#2
use_ok("Net::GNUDBSearch::Cd");
#3
use_ok("Net::GNUDBSearch");

