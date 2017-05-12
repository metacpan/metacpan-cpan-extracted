#!/usr/bin/perl

use Test::More tests => 1;
use Net::OpenID::JanRain::Association;

my @assoc_keys = (
        'version',
        'handle',
        'secret',
        'issued',
        'lifetime',
        'assoc_type',
        );

$issued = time;
$lifetime = 600;
$assoc = Net::OpenID::JanRain::Association->new(
        'handle', 'secret', $issued, $lifetime, 'HMAC-SHA1');
$s = $assoc->serialize();
$assoc2 = Net::OpenID::JanRain::Association->deserialize($s);

ok($assoc->equals($assoc2));

