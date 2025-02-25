use strict;
use warnings;
use Test::More;
use Test::Exception;
use Net::Azure::NotificationHubs;
use Net::Azure::Authorization::SAS;

subtest 'void params' => sub {
    my $hub;
    throws_ok {$hub = Net::Azure::NotificationHubs->new} qr/\Aendpoint was not specified/, 'throws "endpoint was not specified"';
    is $hub, undef, 'fail to create an instance of Net::Azure::NotificationHubs';   
};

subtest 'with connection_string' => sub {
    my $hub = Net::Azure::NotificationHubs->new(
        connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=;EntityPath=myentity'
    );
    isa_ok $hub, 'Net::Azure::NotificationHubs';
    isa_ok $hub->authorizer, 'Net::Azure::Authorization::SAS';
    is $hub->api_version, $Net::Azure::NotificationHubs::DEFAULT_API_VERSION, 'api_version is DEFAULT_API_VERSION';
};

subtest 'with authorizer' => sub {
    my $authorizer = Net::Azure::Authorization::SAS->new(
        connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=;EntityPath=myentity'
    );
    my $hub = Net::Azure::NotificationHubs->new(authorizer => $authorizer);
    isa_ok $hub, 'Net::Azure::NotificationHubs';
    isa_ok $hub->authorizer, 'Net::Azure::Authorization::SAS';
    is $hub->api_version, $Net::Azure::NotificationHubs::DEFAULT_API_VERSION, 'api_version is DEFAULT_API_VERSION';
};

subtest 'with connection_string, api_version' => sub {
    my $hub = Net::Azure::NotificationHubs->new(
        connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=;EntityPath=myentity',
        api_version       => '2020-10',
    );
    isa_ok $hub, 'Net::Azure::NotificationHubs';
    isa_ok $hub->authorizer, 'Net::Azure::Authorization::SAS';
    is $hub->api_version, '2020-10', 'api_version is "2020-10"';
};

subtest 'with connection_string and undefined default values' => sub {
    local $Net::Azure::NotificationHubs::DEFAULT_API_VERSION = undef;

    throws_ok {
        Net::Azure::NotificationHubs->new(
            connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=;EntityPath=myentity',
        );
    } qr/api_version is required/, 'throws "api_version is required"';
};

done_testing;