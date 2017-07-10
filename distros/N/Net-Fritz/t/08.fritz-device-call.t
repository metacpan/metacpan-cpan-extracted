#!perl
use Test::More tests => 7;
use warnings;
use strict;

use Net::Fritz::Box;

BEGIN { use_ok('Net::Fritz::Device') };


### public tests

subtest 'direct call() w/service not found' => sub {
    # given
    my $xmltree = get_xmltree();
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );
    my $service = 'doesnotexist';

    # when
    my $error = $device->call($service);

    # then
    isa_ok( $error, 'Net::Fritz::Error', 'response' );
    like( $error->error, qr/not found/, 'error text as expected' );
    like( $error->error, qr/service/, 'error text refers to missing service' );
};

subtest 'direct call() w/action not found' => sub {
    # given
    my $xmltree = get_xmltree();
    my $fritz = new_ok( 'Net::Fritz::Box' );
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => $fritz, xmltree => $xmltree ] );
    my $service = 'FAKE_SERVICE';
    my $action = 'doesnotexist';

    # when
    my $error = $device->call($service, $action);

    # then
    isa_ok( $error, 'Net::Fritz::Error', 'response' );
    like( $error->error, qr/unknown action/, 'error text as expected' );
    like( $error->error, qr/$action/, 'error text contains action name' );
};

subtest 'direct call() returns result' => sub {
    # given
    my $service = 'MOCK_SERVICE';
    my $action = 'MOCK_ACTION';
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef ] );
    $device->_service_cache->{$service} = Net::Fritz::Service::Mock->new;

    # when
    my $mock_result = $device->call($service, $action);

    # then
    is( $mock_result, 'MOCK_RESULT', 'mocked response' );
};

subtest 'direct call() honors parameters' => sub {
    # given
    my $service = 'MOCK_SERVICE';
    my $action = 'MOCK_ACTION';
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef ] );
    $device->_service_cache->{$service} = Net::Fritz::Service::Mock->new;

    # when
    my $mock_result = $device->call($service, $action, FOO => 'BAR');

    # then
    is( $mock_result, 'MOCK_RESULT_WITH_PARAM', 'mocked response' );
};


### internal tests

subtest 'Net::Fritz::Service cache is empty initially' => sub {
    # given

    # when
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef ] );

    # then
    is_deeply( $device->_service_cache, {}, 'cache' );
};

subtest 'call() adds Net::Fritz::Service to cache if missing' => sub {
    # given
    my $xmltree = get_xmltree();
    my $fritz = new_ok( 'Net::Fritz::Box' );
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => $fritz, xmltree => $xmltree ] );
    my $service = 'FAKE_SERVICE';
    my $action = 'doesnotexist';

    # when
    $device->call($service, $action);

    # then
    my $cached_service = $device->_service_cache->{$service};
    ok( defined $cached_service, 'value is cached' );
    isa_ok( $cached_service, 'Net::Fritz::Service', 'cached value is of expected type' );
    like( $cached_service->serviceType, qr/$service/, 'cached service contains searched name' );
    is( $cached_service->serviceType, 'FAKE_SERVICE_additional_ignored_part_of_name', 'cached service has exected name' );
};


### helper methods

sub get_xmltree
{
    my $xmltree = {
	'serviceList' => [
	    { 'deviceType' => [ 'MAIN_DEVICE' ],
	      'service'    => [
		  { 'serviceType' => [ 'FAKE_SERVICE_additional_ignored_part_of_name' ],
		    'SCPDURL'     => [ '/SCPD' ],
		    'controlURL'  => [ '/control' ],
		  }
		  ]
	    }
	    ]
    }
}


### mock classes

package Net::Fritz::Service::Mock;

sub new {
    return bless {};
}

sub call {
    my ($self, $action, %params) = @_;
    return undef unless $action eq 'MOCK_ACTION';
    return 'MOCK_RESULT_WITH_PARAM' if exists $params{FOO} and $params{FOO} eq 'BAR';
    return 'MOCK_RESULT';
}

sub error {
    return 0;
}

1;
