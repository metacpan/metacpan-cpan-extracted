#!perl -T

use strict;
use warnings;

use Test::More tests => 14;

use Nexmo::SMS::MockLWP;
use Nexmo::SMS;

my $nexmo = Nexmo::SMS->new;

ok $nexmo->isa( 'Nexmo::SMS' ), '$nexmo is a Nexmo::SMS';

my $sms = $nexmo->sms(
    text     => 'This is a test',
    from     => 'Test02',
    to       => '452312432',
    server   => 'http://test.nexmo.com/sms/json',
    username => 'testuser1',
    password => 'testpasswd2',
);

ok $sms->isa( 'Nexmo::SMS::TextMessage' ), '$sms is a Nexmo::SMS::TextMessage';

my $response = $sms->send;

ok $response->isa( 'Nexmo::SMS::Response' ), '$response is a Nexmo::SMS::Response';
ok $response->is_success, 'Send SMS was successful';
ok !$response->is_error, 'Send SMS did not fail';

is $response->message_count, 2, 'Did send two message';

my @messages = $response->messages;
is scalar @messages, 2, 'Got result for two message';

my $message = $messages[0];

ok $message->isa( 'Nexmo::SMS::Response::Message' ), 'object is of type Nexmo::SMS::Response::Message';

is $message->status, 0, 'Status is 0';
is $message->message_id, 'message002';
is $message->client_ref, 'Test002 - Reference', 'A client ref given';
is $message->remaining_balance, '10.0', 'Remaining balance: 10.0';
is $message->message_price, '0.15', 'SMS cost 15 cent';
is $message->error_text, '', 'No error text';