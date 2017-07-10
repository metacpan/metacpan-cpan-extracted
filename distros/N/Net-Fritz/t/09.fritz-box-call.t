#!perl
use Test::More tests => 7;
use warnings;
use strict;

use Test::Mock::LWP::Dispatch;
use HTTP::Response;

BEGIN { use_ok('Net::Fritz::Box') };


### public tests

subtest 'call() returns error when discovery fails' => sub {
    # given
    my $box = new_ok( 'Net::Fritz::Box' );

    # when
    my $error = $box->call();

    # then
    isa_ok( $error, 'Net::Fritz::Error', 'failed discovery' );
};

subtest 'call() returns error when Device::call() fails' => sub {
    # given
    my $box = new_ok( 'Net::Fritz::Box' );
    $box->_ua->map('http://fritz.box:49000/tr64desc.xml', get_fake_device_response());

    # when
    my $error = $box->call('unknown service', 'unknown action');

    # then
    isa_ok( $error, 'Net::Fritz::Error', 'response' );
};

subtest 'call() delegates to Device::call()' => sub {
    # given
    my $box = new_ok( 'Net::Fritz::Box' );
    $box->_device_cache( new_ok( 'Net::Fritz::Device::Mock' ) );

    # when
    my $result = $box->call('MOCK_SERVICE', 'MOCK_ACTION', 'FOO' => 'BAR');

    # then
    is( $result, 'MOCK_RESULT_WITH_PARAM', 'mocked service response' );
};


### internal tests

subtest 'discovered Device gets cached after call()' => sub {
    # given
    my $box = new_ok( 'Net::Fritz::Box' );
    $box->_ua->map('http://fritz.box:49000/tr64desc.xml', get_fake_device_response());

    # when
    $box->call('unknown service', 'unknown action');

    # then
    isa_ok( $box->_device_cache, 'Net::Fritz::Device', 'cached device' );
    is( $box->_device_cache->attributes->{deviceType}, 'FakeDevice:1', 'device type' );
};

subtest 'failed discovery does not get cached after call()' => sub {
    # given
    my $box = new_ok( 'Net::Fritz::Box' );

    # when
    my $error = $box->call();

    # then
    isa_ok( $error, 'Net::Fritz::Error', 'failed discovery' );
    is( $box->_device_cache, undef, 'still no cached device' );
};

subtest 'cached Device is used for next call()' => sub {
    # given
    my $box = new_ok( 'Net::Fritz::Box' );
    $box->_device_cache( new_ok( 'Net::Fritz::Device::Mock' ) );

    # when
    my $result = $box->call('MOCK_SERVICE', 'MOCK_ACTION');

    # then
    is( $result, 'MOCK_RESULT', 'mocked service response' );
};


### helper methods

sub get_fake_device_response
{
    my $xml = get_tr64desc_xml();

    my $result = HTTP::Response->new( 200 );
    $result->content( $xml );
    return $result;
}

sub get_tr64desc_xml
{
    my $tr64_desc_xml = <<EOF;
<?xml version="1.0"?>
<root xmlns="urn:dslforum-org:device-1-0">
  <device>
    <deviceType>FakeDevice:1</deviceType>
  </device>
</root>
EOF
    ;
}


### mock classes

package Net::Fritz::Device::Mock;

sub new {
    return bless {};
}

sub call {
    my ($self, $service, $action, %params) = @_;
    return undef unless $service eq 'MOCK_SERVICE';
    return undef unless $action  eq 'MOCK_ACTION';
    return 'MOCK_RESULT_WITH_PARAM' if exists $params{FOO} and $params{FOO} eq 'BAR';
    return 'MOCK_RESULT';
}

1;
