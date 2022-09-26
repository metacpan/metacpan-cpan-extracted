#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;
use PDK::Firewall::Element::ServiceMeta::Srx;

my $serviceMeta;

ok(
  do {
    eval {
      $serviceMeta = PDK::Firewall::Element::ServiceMeta::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        term     => 'd',
        protocol => 'tcp',
        srcPort  => '1000-1024',
        dstPort  => '135-135'
      );
    };
    warn $@ if !!$@;
    $serviceMeta->isa('PDK::Firewall::Element::ServiceMeta::Srx');
  },
  ' 生成 PDK::Firewall::Element::ServiceMeta::Srx 对象'
);

ok(
  do {
    eval {
      $serviceMeta = PDK::Firewall::Element::ServiceMeta::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        term     => 'd',
        protocol => 'tcp',
        srcPort  => '0-65535',
        dstPort  => '135-135'
      );
    };
    warn $@ if !!$@;
    $serviceMeta->sign eq 'a<|>d';
  },
  ' lazy生成 sign(有 term)'
);

ok(
  do {
    eval {
      $serviceMeta = PDK::Firewall::Element::ServiceMeta::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'tcp',
        srcPort  => '0-65535',
        dstPort  => '135-135'
      );
    };
    warn $@ if !!$@;
    $serviceMeta->sign eq 'a<|> ';
  },
  ' lazy生成 sign(没有 term)'
);

ok(
  do {
    eval {
      $serviceMeta = PDK::Firewall::Element::ServiceMeta::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        term     => 'd',
        protocol => 'tcp',
        srcPort  => '0-65535',
        dstPort  => '135-135'
      );
    };
    warn $@ if !!$@;
    $serviceMeta->dstPortRange->min == 135 and $serviceMeta->dstPortRange->max == 135;
  },
  ' 自动生成dstPortRange'
);

done_testing;
