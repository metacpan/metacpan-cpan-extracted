#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;
use PDK::Firewall::Element::ServiceMeta::Asa;

my $serviceMeta;

ok(
  do {
    eval {
      $serviceMeta
        = PDK::Firewall::Element::ServiceMeta::Asa->new(fwId => 1, srvName => 'Meta', dstPort => '100', protocol => 'tcp');
    };
    warn $@ if !!$@;
    $serviceMeta->isa('PDK::Firewall::Element::ServiceMeta::Asa');
  },
  ' 生成 PDK::Firewall::Element::ServiceMeta::Asa 对象'
);

ok(
  do {
    eval {
      $serviceMeta
        = PDK::Firewall::Element::ServiceMeta::Asa->new(fwId => 1, srvName => 'Meta', dstPort => '100', protocol => 'tcp');
    };
    warn $@ if !!$@;
    $serviceMeta->sign eq 'Meta<|>tcp<|>0-65535<|>100';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $serviceMeta = PDK::Firewall::Element::ServiceMeta::Asa->new(fwId => 1, srvName => 'Meta', dstPort => '40000 40050',
        protocol => 'tcp');
    };
    warn $@ if !!$@;
    $serviceMeta->dstPortRange->min == 40000 and $serviceMeta->dstPortRange->max == 40050;
  },
  ' 自动生成dstPortRange'
);

ok(
  do {
    eval {
      $serviceMeta = PDK::Firewall::Element::ServiceMeta::Asa->new(fwId => 1, srvName => 'Meta', dstPort => '40000-40050',
        protocol => 'tcp');
    };
    warn $@ if !!$@;
    $serviceMeta->dstPortRange->min == 40000 and $serviceMeta->dstPortRange->max == 40050;
  },
  ' 自动生成dstPortRange'
);

done_testing;
