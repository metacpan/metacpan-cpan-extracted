# NATS - Perl Client
A [Perl](http://www.perl.org) client for the [NATS messaging system](https://nats.io).

[![License MIT](https://img.shields.io/npm/l/express.svg)](http://opensource.org/licenses/MIT)

## Installation

To install this module, run the following commands:
```sh
perl Makefile.PL
make
make install
```

## Basic Usage

```perl
$client = Net::NATS::Client->new(uri => 'nats://localhost:4222');
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

# Unsubscribe
$subscription->unsubscribe();

# Close connection
$client->close();
```

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

my $client = Net::NATS::Client->new(uri => 'nats://localhost:4222', socket_args => $socket_args);
$client->connect() or die $!;
```

The MIT License (MIT)
=====================

Copyright © `2016` `Carwyn Moore`

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the “Software”), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
