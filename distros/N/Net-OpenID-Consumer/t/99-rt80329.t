#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use Test::More tests => 1;

use Digest::SHA qw(hmac_sha1_hex);
use Net::OpenID::Consumer;


sub fake_discover_acceptable_endpoints {
    return [{
            uri => 'http://example.com/openid',
            version => 2,
            final_url => 'http://example.com/openid?j.doe',
            sem_info => {},
            mechanism => "HTML",
        }];
}

{
    no warnings 'redefine';
    *Net::OpenID::Consumer::_discover_acceptable_endpoints = \&fake_discover_acceptable_endpoints
}

my $c = Net::OpenID::Consumer->new(
        ua => Fake::UA->new,
        consumer_secret => 'abc',
        args => {
            'oic.time'          => time . '-' . substr(hmac_sha1_hex(time, 'abc'), 0, 20),
            'openid.mode'       => 'id_res',
            'openid.identity'   => 'http://example.com/openid?j.doe',
            'openid.sig'        => 'fake',
            'openid.return_to'  => 'http://example.com/openid',
            'openid.claimed_id' => 'http://example.com/openid?j.doe',
            'openid.something'  => "\x{442}\x{435}\x{441}\x{442}", # this breaks @ uri_escape
            'openid.signed'     => 'mode,identity,return_to,signed,claimed_id,something',
            'openid.assoc_handle' => 'a_handle',
        }
    );

ok(eval { $c->verified_identity() });




package Fake::UA;

sub new {
    return bless {}, "Fake::UA";
}

sub request {
    HTTP::Response->new(200, 'OK', [], "is_valid:true\nlifetime:123");
}
