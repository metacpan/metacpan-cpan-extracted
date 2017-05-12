#!perl
use Test::DescribeMe qw(author);
use Test::More tests => 10;
use warnings;
use strict;

use Net::Fritz::Box;

# connect on normal http port and call a service
my $fritz = new_ok( 'Net::Fritz::Box' );
is( $fritz->error, '', 'get Net::Fritz::Box instance');
isa_ok( $fritz, 'Net::Fritz::Box' );

my $device = $fritz->discover();
is( $device->error, '', 'get Net::Fritz::Device instance');
isa_ok( $device, 'Net::Fritz::Device' );

my $service = $device->find_service('DeviceInfo:1');
is( $service->error, '', 'get DeviceInfo service');
isa_ok( $service, 'Net::Fritz::Service' );

my $response = $service->call('GetSecurityPort');
is( $response->error, '', 'call CatSecurityPort');
isa_ok( $response, 'Net::Fritz::Data' );

my $port = $response->data->{NewSecurityPort};
cmp_ok( $port,  '>', 0, 'get port number');
