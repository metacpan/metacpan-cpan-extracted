#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;
use PDK::Firewall::Element::StaticNat::Asa;

my $staticNat;

ok(
  do {
    eval {
      $staticNat = PDK::Firewall::Element::StaticNat::Asa->new(
        fwId     => 1,
        realZone => 'dmz',
        natZone  => 'trust',
        natIp    => '10.37.172.25',
        realIp   => '192.168.184.25',
      );
    };
    warn $@ if !!$@;
    $staticNat->isa('PDK::Firewall::Element::StaticNat::Asa');
  },
  ' 生成 PDK::Firewall::Element::StaticNat::Asa 对象'
);

ok(
  do {
    eval {
      $staticNat = PDK::Firewall::Element::StaticNat::Asa->new(
        fwId     => 1,
        realZone => 'dmz',
        natZone  => 'trust',
        natIp    => '10.37.172.25',
        realIp   => '192.168.184.25',
      );
    };
    warn $@ if !!$@;
    $staticNat->sign eq '10.37.172.25';
  },
  ' lazy生成 sign'
);

done_testing;
