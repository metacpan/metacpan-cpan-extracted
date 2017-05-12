#!/usr/bin/perl

BEGIN {
    push @INC, './lib/';
}

use STUN::Client;
use Data::Dumper;

$stun_client = STUN::Client->new;

$stun_client->stun_server('stun.xten.com');
$stun_client->local_address('192.168.1.102');
$r = $stun_client->get;

print Dumper($r);

print $stun_client->response->{ma_address},
      ':',
      $stun_client->response->{ma_port}, "\n";

