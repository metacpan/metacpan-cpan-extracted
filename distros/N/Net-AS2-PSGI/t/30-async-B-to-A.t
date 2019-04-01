#
# description: Test PSGI Asynchronised transfer from B to A
#

use Test::More tests => 26;

use strict;
use warnings;

use Cwd                   qw(abs_path);
use HTTP::Request::Common qw(GET POST);
use JSON::XS              qw(decode_json);
use Net::AS2::Message     qw();

use File::Basename        qw(dirname);
use lib dirname(__FILE__) . '/lib';
use TestAS2;

my $dir = abs_path(dirname(__FILE__));

my $a = TestAS2::start('A', 'Server');
is(ref($a), 'Plack::Test::Server', 'Started server A');
ok($a->port, ' on port: ' . $a->port);

my $b = TestAS2::start('B', 'Server');
is(ref($b), 'Plack::Test::Server', 'Started server B');
ok($b->port, ' on port: ' . $b->port);

TestAS2::configure('A', 'A2B', { PORT_A => $a->port, PORT_B => $b->port });
TestAS2::configure('B', 'B2A', { PORT_A => $a->port, PORT_B => $b->port });

my $payload = "PAYLOAD\r\n";

my $message_id = 'async-54321@B2A';

my $request = POST(
    'http://127.0.0.1:' . $b->port . '/send/B2A/async',
    MessageId      => $message_id,
    'Content-Type' => 'text/plain',
    Subject        => 'Sending payload asynchronous request needing MDN receipt',
    Content        => $payload,
);

my $async_resp = $b->request($request);
unlike($async_resp->content, qr{HTTP failure}, 'Received valid HTTP Response') or diag explain $async_resp;

is($async_resp->code, 200, 'Payload in progress response');

my $receiving_file = "$dir/A/files/A2B/async/RECEIVING/$message_id";
ok(-f $receiving_file, "File being received by A $receiving_file");

my $receiving_content = TestAS2::slurp_file($receiving_file);
is($payload, $receiving_content, "File being received by A matched payload sent");

my $receiving_state_file = "$dir/A/files/A2B/async/RECEIVING/$message_id.state";
ok(-f $receiving_state_file, "File state being received by A $receiving_state_file");

my $receiving_state = TestAS2::slurp_file($receiving_state_file);
my $message = Net::AS2::Message->create_from_serialized_state($receiving_state);
is($message->message_id, $message_id, 'File state matches message id');

my $sending_file = "$dir/B/files/B2A/async/SENDING/$message_id.state";
ok(-f $sending_file, "File being sent from B $sending_file");

my $sending_content = decode_json TestAS2::slurp_file($sending_file);
is($sending_content->{mdn}, 'async', 'Confirmation that file being sent is using asynchronous transfer');
is($sending_content->{pending},   1, 'Confirmation that file being sent is still pending completion');

my $mdn_request = POST(
    'http://127.0.0.1:' . $a->port . '/MDNsend/A2B/async',
    MessageId      => $message_id,
);

my $resp = $a->request($mdn_request);
unlike($resp->content, qr{HTTP failure}, 'Received valid HTTP Response') or diag explain $resp;

is($resp->code, 200, 'MDN Async response accepted');

my $received_file = "$dir/A/files/A2B/async/RECEIVED/$message_id";
ok(-f $received_file, "File received by server A $received_file");

my $received_content = TestAS2::slurp_file($received_file);
is($payload, $received_content, "File received by B server matched payload sent");

my $sent_file = "$dir/B/files/B2A/async/SENT/$message_id.state";
ok(-f $sent_file, "File sent by B server $sent_file");

my $sent_content = decode_json TestAS2::slurp_file($sent_file);
is($sent_content->{original_message_id}, $message_id,                'Async Content returned matching original_message_id');
ok($sent_content->{success},                                         'Async Content returned success');
ok(! $sent_content->{is_mdn_async},                                  'Async Content confirmed synchronous MDN');
is($sent_content->{status_text}, '',                                 'Async Content status text is empty');
is($sent_content->{recipient}, 'A',                                  'Async Content confirms payload was sent to recipient');
is($sent_content->{plain_text}, 'Message is received successfully.', 'Async Content returned successful plain text message');

ok(TestAS2::tear_down('A'), 'removed generated test files for A');
ok(TestAS2::tear_down('B'), 'removed generated test files for B');

