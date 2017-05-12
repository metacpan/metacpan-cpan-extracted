#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use warnings;
use strict;
$|=1;

use Test::More tests => 16;
BEGIN { use_ok('Net::MQTT::Constants'); }
use_ok('Net::MQTT::Message');

my $mqtt = Net::MQTT::Message->new(message_type => 15,
                                   remaining => ('X'x129));
ok($mqtt, 'unknown long message');
is($mqtt->string('  '),
   qq{  Reserved15/at-most-once \n}.
   (qq{    58 58 58 58 58 58 58 58 58 58 58 58 58 58 58 58  XXXXXXXXXXXXXXXX\n}
    x 8).
   q{    58                                               X},
   '... string');

is((unpack 'H*', $mqtt->bytes),
   q{f08101}.('58'x129), '... bytes');

my $bytes = pack 'H*', '00';
ok(!Net::MQTT::Message->new_from_bytes($bytes),
   'new_from_bytes - too short');

$bytes .= pack 'H*', '81';
ok(!Net::MQTT::Message->new_from_bytes($bytes),
   'new_from_bytes - still too short 1');

$bytes .= pack 'H*', '01';
ok(!Net::MQTT::Message->new_from_bytes($bytes),
   'new_from_bytes - still too short 2');

$bytes .= 'X';
ok(!Net::MQTT::Message->new_from_bytes($bytes),
   'new_from_bytes - still too short 3');

$bytes .= ('X' x 128).'NEXTMESSAGE';
$mqtt = Net::MQTT::Message->new_from_bytes($bytes, 1);
ok($mqtt, 'new_from_bytes w/splice');
is($bytes, 'NEXTMESSAGE', '... remaining bytes');
is($mqtt->string,
   qq{Reserved0/at-most-once \n}.
   (qq{  58 58 58 58 58 58 58 58 58 58 58 58 58 58 58 58  XXXXXXXXXXXXXXXX\n}
    x 8).
   q{  58                                               X},
   '... string');
is((unpack 'H*', $mqtt->bytes), q{008101}.('58'x129), '... bytes');

$mqtt = Net::MQTT::Message->new(message_type => 1);
ok($mqtt, 'new - connect message');
is($mqtt->client_id, 'NetMQTTpm'.$$, '... client_id');
ok($mqtt->client_id =~ /^[A-Za-z0-9]{1,23}$/, '... client_id in spec');
