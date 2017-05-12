#!/usr/bin/perl

use strict;
use warnings;

use NetAddr::MAC;

my $obj = NetAddr::MAC->new('00:11:33:aa:bb:cc');

print $obj->as_sun,"\n";
