#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;
use PDK::Firewall::Element::StaticNat::Srx;

my $staticNat;

ok(
  do {
    eval {
      $staticNat = PDK::Firewall::Element::StaticNat::Srx->new(
        fwId     => 1,
        ruleName => 'xxx',
        ruleSet  => 'yyy',
        realZone => 'dmz',
        natZone  => 'trust',
        natIp    => '10.37.172.25',
        realIp   => '192.168.184.25',
      );
    };
    warn $@ if !!$@;
    $staticNat->isa('PDK::Firewall::Element::StaticNat::Srx');
  },
  ' 生成 PDK::Firewall::Element::StaticNat::Srx 对象'
);

ok(
  do {
    eval {
      $staticNat = PDK::Firewall::Element::StaticNat::Srx->new(
        fwId     => 1,
        ruleName => 'xxx',
        ruleSet  => 'yyy',
        realZone => 'dmz',
        natZone  => 'trust',
        natIp    => '10.37.172.25',
        realIp   => '192.168.184.25',
      );
    };
    warn $@ if !!$@;
    $staticNat->sign eq 'yyy<|>xxx';
  },
  ' lazy生成 sign'
);

done_testing;
