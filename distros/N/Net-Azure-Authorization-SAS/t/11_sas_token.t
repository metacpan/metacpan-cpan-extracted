use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Time time => 1476061810; # => 2016-10-10 10:10:10

use Net::Azure::Authorization::SAS;

my $sas;

subtest 'new - no connection_string' => sub {
    throws_ok {$sas = Net::Azure::Authorization::SAS->new;} qr/\Aconnection_string is required/;
    is $sas, undef;
};

subtest 'new - normal' => sub {
    $sas = Net::Azure::Authorization::SAS->new(
        connection_string => 'Endpoint=sb://mysvc.servicebus.windows.net/;SharedAccessKeyName=mykey;SharedAccessKey=AexamplekeyAEXAMPLEKEYAexamplekeyAEXAMPLEKEY=;EntityPath=myentity',
    );
    isa_ok $sas, 'Net::Azure::Authorization::SAS';
};

subtest 'token - normal' => sub {
    my $url = 'https://mysvc.servicebus.windows.net/myentity/messages';
    is $sas->token($url), 'SharedAccessSignature sr=https%3a%2f%2fmysvc.servicebus.windows.net%2fmyentity%2fmessages&sig=nQDGh0YxA8O3SFO7SyrmnTK6BnP%2F33KShAbTXFjmYV0%3D&se=1476065410&skn=mykey';
};

subtest 'token - no url' => sub {
    my $token;
    throws_ok {$token = $sas->token} qr/\AAn url for token is required/, 'needs an url';
    is $token, undef;
};

done_testing;