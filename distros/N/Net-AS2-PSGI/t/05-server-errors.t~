#
# description: Test PSGI Synchronised transfer from A to B
#

use Test::More tests => 19;

use strict;
use warnings;

use Cwd                   qw(abs_path);
use HTTP::Request::Common qw(GET POST);
use JSON::XS              qw(decode_json);

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

TestAS2::configure('A', '.', { PORT_A => $a->port, PORT_B => $b->port });
TestAS2::configure('B', 'B2A', { PORT_A => $a->port, PORT_B => $b->port });

my $payload = "PAYLOAD\r\n";

my $message_id = 'sync-abcde@A2B';

my $request = POST(
    'http://127.0.0.1:' . $a->port . '/send/sync',
    MessageId      => "<$message_id>",
    'Content-Type' => 'text/plain',
    Subject        => 'Sending payload synchronised request needing MDN receipt',
    Content        => $payload,
);

my $resp = $a->request($request);
unlike($resp->content, qr{HTTP failure}, 'Received valid HTTP Response') or diag explain $resp;

my $hdrs = $resp->headers;
is($hdrs->header('OriginalMessageId'), $message_id, 'Sync Header returned matching OriginalMessageId');
is($hdrs->content_type, 'application/json',         'Sync Header returned JSON content type');

my $content = decode_json($resp->content);
is($content->{original_message_id}, $message_id,                'Sync Content returned matching original_message_id');
ok($content->{success},                                         'Sync Content returned success');
ok(! $content->{is_mdn_async},                                  'Sync Content confirmed synchronous MDN');
is($content->{status_text}, '',                                 'Sync Content status text is empty');
is($content->{recipient}, 'B',                                  'Sync Content confirms payload was sent to recipient');
is($content->{plain_text}, 'Message is received successfully.', 'Sync Content returned successful plain text message');

my $received_file = "$dir/B/files/B2A/sync/RECEIVED/$message_id";
ok(-f $received_file, "File received by server B $received_file");

my $received_content = TestAS2::slurp_file($received_file);
is($payload, $received_content, "File received by B server matched payload sent");

my $sent_file = "$dir/A/files/sync/SENT/$message_id.state";
ok(-f $sent_file, "File sent to B server $sent_file");

my $sent_mdn = decode_json TestAS2::slurp_file($sent_file);
is_deeply($sent_mdn, $content, "MDN received matches response from Synchronised transfer $sent_file");

ok(TestAS2::tear_down('A'), 'removed generated test files for A');
ok(TestAS2::tear_down('B'), 'removed generated test files for B');

