#!perl
use Test::DescribeMe qw(author);
use Test::More tests => 17;
use warnings;
use strict;

use Net::Fritz::Box;

# connect on normal port to get SSL port (real request)
# connect-http tests this in detail, so skip all those checks
my $fritz = new_ok( 'Net::Fritz::Box' );
is( $fritz->error, '', 'get Net::Fritz::Box instance');

my $device = $fritz->discover();
is( $device->error, '', 'get Net::Fritz::Device instance');

my $service = $device->find_service('DeviceInfo:1');
is( $service->error, '', 'get DeviceInfo service');

my $response = $service->call('GetSecurityPort');
is( $response->error, '', 'call CatSecurityPort');

my $port = $response->data->{NewSecurityPort};
cmp_ok( $port, '>', 0, 'get port number');


# now use the port to call the same service via SSL
my $upnp_url = $fritz->upnp_url;
$upnp_url =~ s/http:/https:/;
$upnp_url =~ s/:49000/:$port/;

my $fritz_ssl = new_ok( 'Net::Fritz::Box' => [ upnp_url => $upnp_url ] );
is ($fritz_ssl->error, '', 'get Net::Fritz::Box instance for SSL');
isa_ok( $fritz_ssl, 'Net::Fritz::Box' );

my $device_ssl = $fritz_ssl->discover();
is( $device_ssl->error, '', 'get Net::Fritz::Device');
isa_ok( $device_ssl, 'Net::Fritz::Device' );

my $service_ssl = $device_ssl->find_service('DeviceInfo:1');
is( $service_ssl->error, '', 'get DeviceInfo service via SSL');
isa_ok( $service_ssl, 'Net::Fritz::Service' );

my $response_ssl = $service_ssl->call('GetSecurityPort');
is( $response_ssl->error, '', 'call CatSecurityPort via SSL');
isa_ok( $response, 'Net::Fritz::Data' );

my $port_ssl = $response_ssl->data->{NewSecurityPort};
cmp_ok( $port_ssl, '>', 0, 'get port number');

is( $port, $port_ssl, 'port number comparison');
