#
# description: Test for expected API errors
#

use Test::More tests => 4;

use strict;
use warnings;

use HTTP::Request::Common qw(GET POST);

use File::Basename        qw(dirname);
use lib dirname(__FILE__) . '/lib';
use TestAS2;

my $a = TestAS2::start('A');
is(ref($a), 'Plack::Test::MockHTTP', 'Started Mocked AS2 server');

TestAS2::configure('A', 'A2B', { PORT_A => 4080, PORT_B => 5080 });

my $payload = "PAYLOAD\r\n";

# Send payload with invalid Message ID.
my $resp = $a->request(POST(
    'http://127.0.0.1/send/A2B/sync',
    MessageId      => '<invalid/AS2TEST>',
    'Content-Type' => 'text/plain',
    Subject        => 'Sending request using invalid ID',
    Content        => $payload,
));

is($resp->code, 500, 'returned 500 error');

like($resp->content,
     qr{Message-Id does not conform to RFC 2822},
     'returned error: Message-Id does not conform to RFC 2822'
);

ok(TestAS2::tear_down('A'), 'removed generated test files for A');
