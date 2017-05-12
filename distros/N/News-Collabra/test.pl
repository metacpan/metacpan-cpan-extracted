# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################
use Test::More tests => 14;

require 't/00stop_start.pl';
require 't/10newsgroup.pl';
require 't/99stop.pl';
