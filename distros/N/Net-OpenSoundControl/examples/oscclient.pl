#!/usr/bin/perl

use strict;
use warnings;
use Net::OpenSoundControl::Client;

my $client =
  Net::OpenSoundControl::Client->new(Host => "127.0.0.1", Port => 7777)
  or die "Could not start Client: $@\n";

print "[OSC Client] Sending out test messages to localhost, port 7777";

$| = 1;
my $i = 1;

while (1) {
    $client->send(
        ['#bundle', 0, ['/Pitch', 'f', rand(1), 'i', 42, 's', "Message $i"]]);
    $i++;
    print ".";
    sleep(1);
}
