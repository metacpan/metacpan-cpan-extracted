#!/usr/bin/env perl
use strict;
use warnings;

use PHP::Serialization;
use Test::More tests => 1;

my $encoded_php =
'a:2:{s:15:"info_buyRequest";a:5:{s:4:"uenc";s:72:"aHR0cDovL3N0YWdpbmcucGNkaXJlY3QuY29tL21vbml0b3JzL2Jsc2FzeTIwMjB3aS5odG1s";s:7:"product";s:3:"663";s:15:"related_product";s:0:"";s:7:"options";a:3:{i:3980;s:5:"12553";i:3981;s:5:"12554";i:3982;s:5:"12555";}s:3:"qty";s:6:"1.0000";}s:7:"options";a:3:{i:0;a:8:{s:5:"label";s:27:"Dead
Pixel Checking Service";s:5:"value";s:155:"I understand LCD technology
might have slight imperfections. Even a high quality A Grade panel might
have up to five dead pixels. Ship without
pre-checking";s:9:"option_id";s:4:"3980";s:3:"sku";s:0:"";s:5:"price";N;s:10:"price_type";N;s:3:"raw";O:33:"Mage_Catalog_Model_Product_Option":15:{s:11:"';

eval q{
	my $u = PHP::Serialization::unserialize($encoded_php);
};

like($@, qr/ERROR/, 'dies');
