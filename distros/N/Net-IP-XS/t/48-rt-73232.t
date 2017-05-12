#!/usr/bin/env perl

use warnings;
use strict;

use Net::IP::XS;

use Test::More tests => 3;

my $ip = Net::IP::XS->new('1:2:3:4:5:6:7');
ok((not $ip), 'Got no object where IPv6 address too short');
is($Net::IP::XS::ERROR,
   'Invalid number of octets 1:2:3:4:5:6:7',
   'Correct error');
is($Net::IP::XS::ERRNO, 112, 'Correct errno');

1;
