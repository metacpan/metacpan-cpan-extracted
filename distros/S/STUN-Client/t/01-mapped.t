#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);

use Test::More tests => 6;
use Test::Exception;

use Data::Validate::IP;

use STUN::Client;

use constant STUN_SERVER => 'stun.xten.com';

BEGIN {
    use_ok ('STUN::Client');
}

our $stun_client = STUN::Client->new;

ok (ref $stun_client eq 'STUN::Client');

lives_ok { $stun_client->stun_server('stun.xten.com') } 'Set stun server';
lives_ok { $stun_client->get } 'Get mapped address!';

my $ma_port = $stun_client->response->{ma_port};
my $ma_address = $stun_client->response->{ma_address};

ok ($ma_port);

ok (is_ipv4($ma_address));

1;

