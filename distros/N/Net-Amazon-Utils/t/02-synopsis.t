use strict;
use warnings;

use Test::More tests => 9;

use lib '../lib';

# Test SYNOPSIS

use Net::Amazon::Utils;

my $utils = Net::Amazon::Utils->new();

# get a list of all regions
my @all_regions = $utils->get_regions();

# get a list of all services abbreviations
my @all_services = $utils->get_services();

# get all endpoints for ec2
my @service_endpoints = $utils->get_service_endpoints( 'ec2' );

my $endpoint_uri;

# check that ec2 exists in region us-west-1
if ( $utils->is_service_supported( 'ec2', 'us-west-1' ) ) {
	# check that http is supported by the end point
	if ( $utils->get_http_support( 'ec2', 'us-west-1' ) ) {
		# get the first http endpoint for ec2 in region us-west-1
		$endpoint_uri =($utils->get_endpoint_uris( 'Http', 'ec2', 'us-west-1' ))[0];
		#... use LWP to POST, send get comments
		#... use Net::Amazon::EC2
	}
}

# get endpoints for ec2 with http support on two given regions
my @some_endpoints = $utils->get_http_support( 'ec2', 'us-west-1', 'us-east-1' );

# check ec2 is supported on all us regions
my @us_regions = grep( /^us/, $utils->get_regions );
my @us_endpoints;
if ( $utils->is_service_supported( 'ec2', @us_regions ) ) {
	# get endpoints for ec2 with http support on all us regions
	@us_endpoints = $utils->get_http_support( 'ec2', @us_regions );
	# choose a random one and give you images a spin
	# ...
}

# END SYNOPSIS

ok( @all_regions, 'SYNOPSIS all_regions.' );
ok( @all_services, 'SYNOPSIS all_services.' );
ok( grep( /ec2/, @service_endpoints ), 'SYNOPSIS service_endpoints.' );
ok( $utils->is_service_supported( 'ec2', 'us-west-1' ), 'SYNOPSIS service supported.' );
ok( $utils->get_http_support( 'ec2', 'us-west-1' ), 'SYNOPSIS http support.' );
is( $endpoint_uri, 'http://ec2.us-west-1.amazonaws.com', 'SYNOPSIS endpoint_uri.' );
is( @some_endpoints, 2, 'SYNOPSIS some_endpoints.');
is( @us_regions, 4, 'SYNOPSIS us_regions.');
is( @us_endpoints, 3, 'SYNOPSIS us_endpoints.');
