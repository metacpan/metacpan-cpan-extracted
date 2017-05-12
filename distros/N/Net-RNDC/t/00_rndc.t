#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Net::RNDC;

my $rndc = Net::RNDC->new();
ok($rndc, 'Got an rndc object');

done_testing;
