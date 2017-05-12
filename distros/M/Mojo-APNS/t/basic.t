use warnings;
use strict;
use Test::More;
use Mojo::APNS;

my $apns = Mojo::APNS->new;

is $apns->key,              '',                               'default value for key';
is $apns->cert,             '',                               'default value for cert';
is $apns->sandbox,          1,                                'default value for sandbox';
is $apns->_gateway_port,    '2195',                           'default value for _gateway_port';
is $apns->_feedback_port,   '2196',                           'default value for _feedback_port';
is $apns->_gateway_address, 'gateway.sandbox.push.apple.com', 'default value for _gateway_address';
isa_ok $apns->ioloop,       'Mojo::IOLoop';

delete $apns->{_gateway_address};
$apns->sandbox(0);
is $apns->_gateway_address, 'gateway.push.apple.com', 'production _gateway_address';

done_testing;
