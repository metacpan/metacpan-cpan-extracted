use strict;
use warnings;

use Test::More;
use Encode qw(encode_utf8);
use Net::NATS2::Client;
use Net::NATS2::ServerInfo;

{
    package Local::Connection;

    sub new { bless {}, shift }

    sub send {
        $_[0]->{sent} = $_[1];
        return 1;
    }

    sub sent { $_[0]->{sent} }
}

{
    package Local::Client;

    our @ISA = ('Net::NATS2::Client');

    sub read { $_[0]->{content} }
}

{
    package Local::Subscription;

    sub callback               { $_[0]->{callback} }
    sub message_count : lvalue { $_[0]->{message_count} }
    sub defined_max            {0}
}

my $connection = Local::Connection->new;
my $client     = Local::Client->new;
$client->connection($connection);

my $headers = "NATS/1.0\r\nX-Trace-ID: 42\r\n\r\n";
my $data    = 'hello';
ok($client->hpublish('headers.test', $headers, $data, 'reply.test'), 'sends HPUB',);
is(
    $connection->sent,
    'HPUB headers.test reply.test ' . length($headers) . ' ' . (length($headers) + length($data)) . "\r\n$headers$data",
    'HPUB includes reply subject and correct byte lengths',
);

my $message;
$client->subscriptions({1 => bless({message_count => 0, callback => sub { ($message) = @_ },}, 'Local::Subscription'),
});
$client->{content} = $headers . $data . "\r\n";
$client->_handle_op('HMSG', 'headers.test', 1, 'reply.test', length($headers), length($headers) + length($data));

is($message->subject,       'headers.test',   'HMSG preserves subject');
is($message->reply_to,      'reply.test',     'HMSG preserves reply subject');
is($message->header_length, length($headers), 'HMSG exposes header length');
is($message->headers,       $headers,         'HMSG exposes raw headers');
is($message->length,        length($data),    'HMSG payload length excludes headers');
is($message->data,          $data,            'HMSG extracts payload');
is($client->message_count,  1,                'HMSG increments client message count');

my $unicode_data = "\N{U+2713}";
$client->hpublish('headers.utf8', $headers, $unicode_data);
is(
    $connection->sent,
    'HPUB headers.utf8 '
        . length($headers) . ' '
        . (length($headers) + length(encode_utf8($unicode_data)))
        . "\r\n$headers$unicode_data",
    'HPUB declares UTF-8 payload byte length',
);

ok($client->publish('publish.utf8', $unicode_data), 'sends PUB with UTF-8 payload');
is(
    $connection->sent,
    'PUB publish.utf8 ' . length(encode_utf8($unicode_data)) . "\r\n$unicode_data",
    'PUB declares UTF-8 payload byte length',
);

$client->server_info(Net::NATS2::ServerInfo->new(headers => 0));
ok(!$client->hpublish('headers.unsupported', $headers, $data), 'does not send HPUB to a server without header support');

done_testing;
