#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;
use PDK::Firewall::Element::ServiceMeta::Hillstone;

my $serviceMeta;

ok(
  do {
    eval {
      $serviceMeta = PDK::Firewall::Element::ServiceMeta::Hillstone->new(
        srvName  => 'xxxx',
        fwId     => 1,
        dstPort  => '100-2000',
        protocol => 'tcp'
      );
    };
    warn $@ if !!$@;
    $serviceMeta->isa('PDK::Firewall::Element::ServiceMeta::Hillstone');
  },
  ' 生成 PDK::Firewall::Element::ServiceMeta::Hillstone 对象'
);

ok(
  do {
    eval {
      $serviceMeta = PDK::Firewall::Element::ServiceMeta::Hillstone->new(
        srvName  => 'xxxx',
        fwId     => 1,
        dstPort  => '100-2000',
        protocol => 'tcp'
      );
    };
    warn $@ if !!$@;
    $serviceMeta->sign eq 'xxxx<|>tcp<|>0-65535<|>100-2000';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $serviceMeta = PDK::Firewall::Element::ServiceMeta::Hillstone->new(
        srvName  => 'xxxx',
        fwId     => 1,
        dstPort  => '40000 40050',
        protocol => 'tcp'
      );
    };
    warn $@ if !!$@;
    $serviceMeta->dstPortRange->min == 40000 and $serviceMeta->dstPortRange->max == 40050;
  },
  ' 自动生成dstPortRange'
);

ok(
  do {
    eval {
      $serviceMeta = PDK::Firewall::Element::ServiceMeta::Hillstone->new(
        srvName  => 'xxxx',
        fwId     => 1,
        dstPort  => '40000-40050',
        protocol => 'tcp'
      );
    };
    warn $@ if !!$@;
    $serviceMeta->dstPortRange->min == 40000 and $serviceMeta->dstPortRange->max == 40050;
  },
  ' 自动生成dstPortRange'
);

done_testing;
