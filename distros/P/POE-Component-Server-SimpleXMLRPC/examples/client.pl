#!/usr/bin/perl

use strict;
use warnings;

use Frontier::Client;

# set up remote service url
my $service_url = 'http://localhost:5555';

# remote procedure to call
my $procedure = 'test';

# data to post to remote method
my $data = { arg1 => 'value1', arg2 => 'value2' };

# xml-rpc client object
my $xml_rpc = Frontier::Client->new( url => $service_url );

# response from server
my $response = $xml_rpc->call( $procedure, $data );

# Just for test
use Data::Dumper;
print Dumper( $response );
