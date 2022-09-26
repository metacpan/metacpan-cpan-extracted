#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;

use PDK::Firewall::Element::Service::Srx;
use PDK::Firewall::Element::ServiceMeta::Srx;
my $service;

ok(
  do {
    eval {
      $service = PDK::Firewall::Element::Service::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559',
        term     => 'd'
      );
    };
    warn $@ if !!$@;
    $service->isa('PDK::Firewall::Element::Service::Srx');
  },
  ' 生成 PDK::Firewall::Element::Service::Srx 对象'
);

ok(
  do {
    eval {
      $service = PDK::Firewall::Element::Service::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559',
        term     => 'd'
      );
    };
    warn $@ if !!$@;
    $service->sign eq 'a';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $service = PDK::Firewall::Element::Service::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559',
        term     => 'z'
      );
    };
    warn $@ if !!$@;
    $service->addMeta(fwId => 1, srvName => 'a', protocol => 'd', srcPort => 'c', dstPort => '1520-1523', term => 'y');
    $service->metas->{'a<|>z'}->sign eq 'a<|>z'
      and $service->dstPortRangeMap->{'d'}->min == 1520
      and $service->dstPortRangeMap->{'d'}->max == 1523;
  },
  " addMeta( fwId => 1, srvName => 'a', protocol => 'd', srcPort => 'c', dstPort => '1520-1523', term => 'y' )"
);

ok(
  do {
    eval {
      $service = PDK::Firewall::Element::Service::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559',
        term     => 'z'
      );
    };
    warn $@ if !!$@;
    $service->addMeta(PDK::Firewall::Element::ServiceMeta::Srx->new(
      fwId     => 1,
      srvName  => 'a',
      protocol => 'd',
      srcPort  => 'c',
      dstPort  => '1520-1523',
      term     => 'y'
    ));
    $service->metas->{'a<|>z'}->sign eq 'a<|>z'
      and $service->dstPortRangeMap->{'d'}->min == 1520
      and $service->dstPortRangeMap->{'d'}->max == 1523;
  },
  " addMeta( PDK::Firewall::Element::ServiceMeta::Srx )"
);

ok(
  do {
    eval {
      $service = PDK::Firewall::Element::Service::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559',
        term     => 'z'
      );
      $service->addMeta(PDK::Firewall::Element::ServiceMeta::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'd',
        srcPort  => 'c',
        dstPort  => '1525-1559',
        term     => 'y'
      ));
      my $anotherService = PDK::Firewall::Element::Service::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1520-1523',
        term     => 'x'
      );
      $anotherService->addMeta(PDK::Firewall::Element::ServiceMeta::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'f',
        srcPort  => 'c',
        dstPort  => '1525-1559',
        term     => 'w'
      ));
      $service->addMeta($anotherService);
    };
          $service->metas->{'a<|>z'}->sign eq 'a<|>z'
      and $service->dstPortRangeMap->{'b'}->mins->[0] == 1520
      and $service->dstPortRangeMap->{'b'}->maxs->[0] == 1523
      and $service->dstPortRangeMap->{'b'}->mins->[1] == 1525
      and $service->dstPortRangeMap->{'b'}->maxs->[1] == 1559;
  },
  " addMeta( PDK::Firewall::Element::Service::Srx )"
);

done_testing;
