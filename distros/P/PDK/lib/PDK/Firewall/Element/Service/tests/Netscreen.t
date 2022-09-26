#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;

use PDK::Firewall::Element::Service::Netscreen;
use PDK::Firewall::Element::ServiceMeta::Netscreen;

my $service;

ok(
  do {
    eval {
      $service = PDK::Firewall::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
    };
    warn $@ if !!$@;
    $service->isa('PDK::Firewall::Element::Service::Netscreen');
  },
  ' 生成 PDK::Firewall::Element::Service::Netscreen 对象'
);

ok(
  do {
    eval {
      $service = PDK::Firewall::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
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
      $service = PDK::Firewall::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
    };
    warn $@ if !!$@;
    $service->addMeta(fwId => 1, srvName => 'a', protocol => 'd', srcPort => 'c', dstPort => '1525-1559');
    $service->metas->{'a<|>b<|>c<|>1525-1559'}->sign eq 'a<|>b<|>c<|>1525-1559'
      and $service->dstPortRangeMap->{'b'}->min == 1525
      and $service->dstPortRangeMap->{'b'}->max == 1559;
  },
  " addMeta( fwId => 1, srvName => 'a', protocol => 'd', srcPort => 'c', dstPort => '1525-1559' )"
);

ok(
  do {
    eval {
      $service = PDK::Firewall::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
    };
    warn $@ if !!$@;
    $service->addMeta(PDK::Firewall::Element::ServiceMeta::Netscreen->new(
      fwId     => 1,
      srvName  => 'a',
      protocol => 'd',
      srcPort  => 'c',
      dstPort  => '1525-1559'
    ));
    $service->metas->{'a<|>d<|>c<|>1525-1559'}->sign eq 'a<|>d<|>c<|>1525-1559'
      and $service->dstPortRangeMap->{'d'}->min == 1525
      and $service->dstPortRangeMap->{'d'}->max == 1559;
  },
  " addMeta( PDK::Firewall::Element::ServiceMeta::Netscreen )"
);

ok(
  do {
    eval {
      $service = PDK::Firewall::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
      $service->addMeta(PDK::Firewall::Element::ServiceMeta::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'd',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      ));
      my $anotherService = PDK::Firewall::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1520-1523'
      );
      $anotherService->addMeta(PDK::Firewall::Element::ServiceMeta::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'f',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      ));
      $service->addMeta($anotherService);
    };
    warn $@ if !!$@;
          $service->metas->{'a<|>f<|>c<|>1525-1559'}->sign eq 'a<|>f<|>c<|>1525-1559'
      and $service->dstPortRangeMap->{b}->mins->[0] == 1520
      and $service->dstPortRangeMap->{b}->maxs->[0] == 1523
      and $service->dstPortRangeMap->{b}->mins->[1] == 1525
      and $service->dstPortRangeMap->{b}->maxs->[1] == 1559;
  },
  " addMeta( PDK::Firewall::Element::Service::Netscreen )"
);

ok(
  do {
    eval {
      $service = PDK::Firewall::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
      $service->addMeta(PDK::Firewall::Element::ServiceMeta::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'd',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      ));
      my $anotherService = PDK::Firewall::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1520-1523'
      );
      $anotherService->addMeta(PDK::Firewall::Element::ServiceMeta::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'f',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      ));
      $service->addMeta($anotherService);
    };
    warn $@ if !!$@;
    my $timeout = 10;
    $service->setTimeout($timeout);
          $service->timeout == $timeout
      and $service->metas->{'a<|>b<|>c<|>1525-1559'}->timeout == $timeout
      and $service->metas->{'a<|>d<|>c<|>1525-1559'}->timeout == $timeout
      and $service->metas->{'a<|>b<|>c<|>1520-1523'}->timeout == $timeout
      and $service->metas->{'a<|>f<|>c<|>1525-1559'}->timeout == $timeout;
  },
  " setTimeout and timeout"
);

done_testing;
