#!/usr/bin/env perl

use strict;
use FindBin qw($Bin);
use Test::More tests => 7;
my $base_uri = 'http://localhost';

use_ok('RDF::LinkedData');

my $store = { storetype => 'Memory',
				  sources => [ { file => $Bin . '/data/basic.ttl',
									 syntax => 'turtle'
								  } ] };

{
	my $ld = RDF::LinkedData->new(store => $store, base_uri=>$base_uri);
	isa_ok($ld, 'RDF::LinkedData');
	is($ld->count, 3, "There are 3 triples in model");
	ok(!$ld->has_endpoint_config, 'No endpoint configured');
}

{
	my $ld = RDF::LinkedData->new(store => $store, endpoint_config => undef, base_uri=>$base_uri);
	isa_ok($ld, 'RDF::LinkedData');
	is($ld->count, 3, "There are 3 triples in model");
	ok(!$ld->has_endpoint_config, 'No endpoint configured');
}

done_testing;
