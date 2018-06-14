use strict;
use warnings;
use Test::More;
use Test::Exception;
use Net::Azure::EventHubs;
use Net::Azure::Authorization::SAS;

subtest 'void params' => sub {
    my $hub;
    throws_ok {$hub = Net::Azure::EventHubs->new} qr/\Aendpoint was not specified/, 'throws "endpoint was not specified"';
    is $hub, undef, 'fail to create an instance of Net::Azure::EventHubs';   
};

subtest 'with connection_string' => sub {
    my $hub = Net::Azure::EventHubs->new(
        connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=;EntityPath=myentity'
    );
    isa_ok $hub, 'Net::Azure::EventHubs';
    isa_ok $hub->authorizer, 'Net::Azure::Authorization::SAS';
    is $hub->api_version, $Net::Azure::EventHubs::DEFAULT_API_VERSION, 'api_version is DEFAULT_API_VERSION';
    is $hub->timeout, $Net::Azure::EventHubs::DEFAULT_TIMEOUT, 'timeout is DEFAULT_TIMEOUT';
};

subtest 'with authorizer' => sub {
    my $authorizer = Net::Azure::Authorization::SAS->new(
        connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=;EntityPath=myentity'
    );
    my $hub = Net::Azure::EventHubs->new(authorizer => $authorizer);
    isa_ok $hub, 'Net::Azure::EventHubs';
    isa_ok $hub->authorizer, 'Net::Azure::Authorization::SAS';
    is $hub->api_version, $Net::Azure::EventHubs::DEFAULT_API_VERSION, 'api_version is DEFAULT_API_VERSION';
    is $hub->timeout, $Net::Azure::EventHubs::DEFAULT_TIMEOUT, 'timeout is DEFAULT_TIMEOUT';
};

subtest 'with connection_string, api_version, and timeout' => sub {
    my $hub = Net::Azure::EventHubs->new(
        connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=;EntityPath=myentity',
        api_version       => '2020-10',
        timeout           => 120,
    );
    isa_ok $hub, 'Net::Azure::EventHubs';
    isa_ok $hub->authorizer, 'Net::Azure::Authorization::SAS';
    is $hub->api_version, '2020-10', 'api_version is "2020-10"';
    is $hub->timeout, 120, 'timeout is 120';
};

subtest 'with connection_string and undefined default values' => sub {
    local $Net::Azure::EventHubs::DEFAULT_API_VERSION = undef;
    local $Net::Azure::EventHubs::DEFAULT_TIMEOUT     = undef;

    my $hub = Net::Azure::EventHubs->new(
        connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=;EntityPath=myentity',
    );

    isa_ok $hub, 'Net::Azure::EventHubs';
    isa_ok $hub->authorizer, 'Net::Azure::Authorization::SAS';
    is $hub->api_version, undef, 'api_version is undef';
    is $hub->timeout, undef, 'timeout is undef';
};

done_testing;