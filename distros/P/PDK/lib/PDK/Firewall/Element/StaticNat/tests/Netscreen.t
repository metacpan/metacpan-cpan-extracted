#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Mojo::Util qw(dumper);
use PDK::Firewall::Element::StaticNat::Netscreen;

my $staticNat;

ok(
  do {
    eval {
      $staticNat = PDK::Firewall::Element::StaticNat::Netscreen->new(
        fwId     => 1,
        realZone => 'dmz',
        natZone  => 'trust',
        natIp    => '10.37.172.25',
        realIp   => '192.168.184.25',
        mask     => '32'
      );
    };
    warn $@ if !!$@;
    $staticNat->isa('PDK::Firewall::Element::StaticNat::Netscreen');
  },
  ' 生成 PDK::Firewall::Element::StaticNat::Netscreen 对象'
);

ok(
  do {
    eval {
      $staticNat = PDK::Firewall::Element::StaticNat::Netscreen->new(
        fwId     => 1,
        realZone => 'dmz',
        natZone  => 'trust',
        natIp    => '10.37.172.25',
        realIp   => '192.168.184.25',
        mask     => '32'
      );
    };
    warn $@ if !!$@;
    $staticNat->sign eq '10.37.172.25';
  },
  ' lazy生成 sign'
);

done_testing;
