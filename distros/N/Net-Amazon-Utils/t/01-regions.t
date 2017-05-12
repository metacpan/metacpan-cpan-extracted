use strict;
use warnings;

use Test::More tests => 43;

use lib '../lib';

BEGIN {
	use_ok( 'Carp' );
	use_ok( 'XML::Simple' );
	use_ok( 'LWP::UserAgent' );
	use_ok( 'Net::Amazon::Utils' );
	use_ok( 'Net::Amazon::Utils::Regions' );
}

# Test with caching and no Internet connection

my $utils = Net::Amazon::Utils->new( 0, 1 );
my @methods = qw( get_regions fetch_region_update
		get_services get_service_endpoints get_http_support get_https_support
		get_service_endpoint is_service_supported has_http_endpoint has_https_endpoint has_protocol_endpoint
		get_known_protocols set_known_protocols reset_known_protocols get_endpoint_uris );

# Test object interface

isa_ok( $utils, 'Net::Amazon::Utils' );
can_ok( $utils, @methods );

# Test Regions

ok( scalar $utils->get_regions() > 0, 'Regions returns at least one region.' );
is( grep( /^us-east-1$/, $utils->get_regions() ), 1, 'Region us-east-1 shall always exist.');
is( grep( /^us-west-1$/, $utils->get_regions() ), 1, 'Region us-west-1 shall always exist.');
is( grep( /^us-west-2$/, $utils->get_regions() ), 1, 'Region us-west-2 shall always exist.');

# Test Services

my @services = $utils->get_services();
isnt( scalar @services, 0, 'Services returns at least one service.' );
ok( grep( /^ec2$/, @services ), 'Service ec2 shall always exist.');
ok( grep( /^s3$/, @services ), 'Service s3 shall always exist.');
ok( grep( /^sqs$/, @services ), 'Service sqs shall always exist.');
ok( grep( /^glacier$/, @services ), 'Service glacier shall always exist.');

ok( scalar $utils->get_service_endpoints( 'ec2' ) > 0, 'Service endpoints for ec2 exist.' );
ok( scalar $utils->get_service_endpoints( 's3' ) > 0, 'Service endpoints for s3 exist.' );
ok( scalar $utils->get_service_endpoints( 'sqs' ) > 0, 'Service endpoints for sqs exist.' );
ok( scalar $utils->get_service_endpoints( 'glacier' ) > 0, 'Service endpoints for glacier exist.' );

# Test protocol support

ok( scalar $utils->get_known_protocols() == 2, 'There are two known protocols.' );
my @protocols = $utils->get_known_protocols();
ok( scalar $utils->set_known_protocols( 'Http' ) == 1, 'Sets a single protocol.' );
ok( scalar $utils->set_known_protocols( @protocols ) == 2, 'Sets two protocols.' );
ok( scalar $utils->get_known_protocols() == 2, 'Protocols ok after user reset.' );
$utils->reset_known_protocols();
ok( scalar $utils->get_known_protocols() == 2, 'Protocols ok after class reset.' );


# Test endpoint protocol support

ok( scalar $utils->get_http_support( 'sqs') > 0, 'There is at least one http endpoint for sqs.' );
ok( scalar $utils->get_http_support( 'sqs') > 0, 'There is at least one http endpoint for sqs, cached.' );
ok( scalar $utils->get_https_support( 'sqs') > 0, 'There is at least one https endpoint for sqs.' );
ok( scalar $utils->get_https_support( 'sqs') > 0, 'There is at least one https endpoint for sqs, cached.' );
ok( scalar $utils->get_http_support( 'sqs', 'us-west-1' ) == 1, 'There is one http endpoint for sqs in a single region.' );
ok( scalar $utils->get_http_support( 'sqs', 'us-west-1' ) == 1, 'There is one https endpoint for sqs in a single region.' );
ok( scalar $utils->get_http_support( 'sqs', 'us-west-1', 'us-east-1' ) == 2, 'There is at least two http endpoint for sqs in a list two regions.' );
ok( scalar $utils->get_http_support( 'sqs', 'us-west-1', 'us-east-1' ) == 2, 'There is at least two http endpoint for sqs in a list two regions, cached.' );
ok( scalar $utils->get_https_support( 'sqs', 'us-west-1', 'us-east-1' ) == 2, 'There is at least two https endpoint for sqs in a list two regions.' );
ok( scalar $utils->get_https_support( 'sqs', 'us-west-1', 'us-east-1' ) == 2, 'There is at least two https endpoint for sqs in a list two regions, cached.' );

# Test specific services

ok( $utils->is_service_supported( 'ec2', 'us-west-1' ), 'us-west-1->ec2 exists.' );
ok( $utils->is_service_supported( 's3' , 'us-west-1' ), 'us-west-1->s3 exists.' );
ok( $utils->is_service_supported( 'sqs', 'us-west-1' ), 'us-west-1->sqs exists.' );
ok( $utils->is_service_supported( 'glacier', 'us-west-1' ), 'us-west-1->glacier exists.' );

# Test specific endpoints

ok( $utils->has_http_endpoint( 'glacier', 'us-west-1', ), 'us-west-1->glacier has http endpoint.' );
ok( $utils->has_https_endpoint( 'glacier', 'us-west-1', ), 'us-west-1->glacier has https endpoint.' );
ok( $utils->has_protocol_endpoint( 'Http', 'glacier', 'us-west-1' ), 'us-west-1->glacier has an http endpoint when checked with generic function.' );

# Test assembling uris

is( ($utils->get_endpoint_uris( 'Http', 'glacier', 'us-west-1' ))[0], 'http://glacier.us-west-1.amazonaws.com', 'Correct URI for http glacier on us-west-1' );
