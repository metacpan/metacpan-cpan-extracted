#!/usr/bin/perl -T

use lib 'lib';

use Test::More;
plan tests => 1;

use strict;
use warnings;

use Net::validMX;

#OO METHOD
my $valid = Net::validMX->new(allow_ip_address_as_mx=>0, debug=>1);
my ($rv, $reason) = $valid->check_valid_mx(email=>'kevin@mcgrail.com', debug=>1, allow_ip_address_as_mx=>0);
is($rv, 1);
