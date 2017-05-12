#!/usr/bin/env perl 

use warnings;
use strict;

use lib '../lib';

use NetSDS::EDR;
use Data::Dumper;

my $edr = NetSDS::EDR->new(filename=>'/tmp/edrfile');

#print NetSDS::EDR->errstr;
print Dumper($edr);

$edr->write(
	{
		msgid => '123123@system.name',
		src_addr => '1234@mts',
		dst_addr => '380501234567@mts',
		tm => time,
	},
	{
		msgid => '123123@system.name',
		src_addr => '1234@kyivstar',
		dst_addr => '380672222222@ks',
		tm => time,
	},
);
1;
