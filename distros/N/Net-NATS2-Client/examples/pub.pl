#!/usr/bin/perl

use strict;
use warnings;

use Net::NATS2::Client;

my $socket_args = {
    SSL_cert_file => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    SSL_key_file => '/etc/ssl/private/ssl-cert-snakeoil.key',
};

my $client = Net::NATS2::Client->new(uri => 'nats://localhost:4222', socket_args => $socket_args);
$client->connect() or die $!;

while(1) {
    $client->publish("foo", 'Hello, World!');
}
