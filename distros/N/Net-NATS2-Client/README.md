# Net::NATS2::Client

A [Perl](http://www.perl.org) client for the [NATS messaging system](https://nats.io).

This project is based on [Net::NATS::Client by Carwyn Moore](https://github.com/carwynmoore/perl-nats).

## Installation

To install this module, run the following commands:
```sh
perl Makefile.PL
make
make install
```

## Basic Usage

```perl
$client = Net::NATS2::Client->new(uri => 'nats://localhost:4222');
$client->connect() or die $!;

# Simple Publisher
$client->publish('foo', 'Hello, World!');

# Simple Async Subscriber
$subscription = $client->subscribe('foo', sub {
    my ($message) = @_;
    printf("Received a message: %s\n", $message->data);
});

# Process one message from the server. Could be a PING message.
# Must call at least one per ping-timout (default is 120s).
$client->wait_for_op();

# Process pending operations, with a timeout (in seconds).
# A timeout of 0 is polling.
$client->wait_for_op(3.14);

# Check that the connection is still live.  This waits up to one second
# for the server's PONG response.
die 'ERROR: Connection lost!' unless $client->ping(1);

# Unsubscribe
$subscription->unsubscribe();

# Close connection
$client->close();
```

## Headers

Use `hpublish` (or `publish_with_headers`) to send an `HPUB` command. Headers
are passed as a complete NATS header block, including the `NATS/1.0` version
line and terminating blank line. Received header messages expose that block
through `$message->headers`; `$message->data` contains only the payload. An
optional fourth argument supplies the reply subject.

```perl
my $headers = "NATS/1.0\r\nX-Trace-ID: 42\r\n\r\n";
$client->hpublish('foo', $headers, 'Hello, World!');
```

The client advertises header support during `CONNECT` and will not send an
`HPUB` command if the server's `INFO` message reports no header support. Text
payloads are UTF-8 encoded before sending; byte strings are sent unchanged.

## NKey authentication

Pass the user NKey public key in `nkey` and a callback in `nkey_sig_cb` that
signs the server nonce. The callback receives the nonce and must return the raw
Ed25519 signature bytes; the client encodes the signature for `CONNECT`.

```perl
use Crypt::PK::Ed25519;

my $signer = Crypt::PK::Ed25519->new('/secure/path/user-ed25519.pem');
# The NATS-encoded public NKey matching the private key loaded above.
my $nkey = $ENV{NATS_USER_NKEY};
my $client = Net::NATS2::Client->new(
    uri         => 'nats://localhost:4222',
    nkey        => $nkey,
    nkey_sig_cb => sub {
        my ($nonce) = @_;
        return $signer->sign_message($nonce);
    },
);
```

## Reconnection

Automatic reconnection is disabled by default. Enable it to retry a lost
read-side connection and restore all existing subscriptions with their original
subscription IDs:

```perl
my $client = Net::NATS2::Client->new(
    uri                => 'nats://localhost:4222',
    auto_reconnect     => 1,
    reconnect_attempts => 3,
    reconnect_delay    => 1,
);
```

Failed publishes are not retried automatically, because the server may have
accepted the message before the connection failure; retrying could duplicate
delivery.

Set `auto_reconnect => 0` for unlimited reconnect attempts. Omit
`auto_reconnect` entirely to disable reconnection.

## JetStream

`Net::NATS2::JetStream` provides account information, stream management, and
synchronous publish acknowledgements. It uses the connected core NATS client.

```perl
use Net::NATS2::JetStream;

my $js = Net::NATS2::JetStream->new(client => $client, timeout => 1);
$js->add_stream({
    name     => 'ORDERS',
    subjects => ['orders'],
    storage  => 'memory',
}) or die $js->last_error->{description};

my $ack = $js->publish('orders', 'created')
    or die $js->last_error->{description};
printf "Stored in %s at sequence %d\n", $ack->{stream}, $ack->{seq};

$js->purge_stream('ORDERS');
$js->delete_stream('ORDERS');
```

The supported stream operations are `api_info`, `add_stream`, `update_stream`,
`stream_info`, `stream_list`, `purge_stream`, and `delete_stream`. Methods
return decoded JetStream API responses. On a timeout, invalid response, or
JetStream error, they return `undef`; inspect `last_error` for details.

### Pull consumers

Create a pull consumer with no `deliver_subject`, then retrieve one or more
messages on demand. Messages carry a reply subject used by the acknowledgement
methods.

```perl
$js->add_consumer('ORDERS', {
    durable_name => 'WORKER',
    ack_policy   => 'explicit',
});

my $message = $js->next_message('ORDERS', 'WORKER') or die 'No message';
process($message->data);
$js->ack($message);

my $messages = $js->fetch('ORDERS', 'WORKER', 10);
for my $message (@$messages) {
    process($message->data);
    $js->ack($message);       # or $js->nak($message), $js->term($message)
}
```

`fetch` returns an array reference and may return fewer than the requested
batch when the server has no further messages before the timeout.

## Request

```perl
# Setup reply
$client->subscribe("foo", sub {
    my ($request) = @_;
    printf("Received request: %s\n", $request->data);
    $client->publish($request->reply_to, "Hello, Human!");
});

# Send request
$client->request('foo', 'Hello, World!', sub {
    my ($reply) = @_;
    printf("Received reply: %s\n", $reply->data);
});
```

## TLS

```perl
# Set the socket arguments that will be passed to IO::Socket::SSL
my $socket_args = {
    SSL_cert_file => $cert_file,
    SSL_key_file  => $key_file,
};

my $client = Net::NATS2::Client->new(uri => 'nats://localhost:4222', socket_args => $socket_args);
$client->connect() or die $!;
```

## Read Buffer Size

The client reads from the socket in 1024-byte chunks by default. Set
`BufferSize` in `socket_args` to use a different chunk size:

```perl
my $client = Net::NATS2::Client->new(
    uri => 'nats://localhost:4222',
    socket_args => { BufferSize => 4096 },
);
```

## License

MIT. See [LICENSE](LICENSE).
