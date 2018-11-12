#!/usr/bin/perl

use strict;
use warnings;

use Net::NATS::Client;

my $socket_args = {
    SSL_cert_file => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    SSL_key_file => '/etc/ssl/private/ssl-cert-snakeoil.key', 
};

my $client = Net::NATS::Client->new(uri => 'nats://localhost:4222', socket_args => $socket_args);
$client->connect() or die $!;

my $sub = $client->subscribe("foo", sub {
    my ($message) = @_;
    print $message->data . "\n";
});

my $count = 0;
while ($client->wait_for_op) {
    $client->close if $count++ > 10;
}
print "done\n";
