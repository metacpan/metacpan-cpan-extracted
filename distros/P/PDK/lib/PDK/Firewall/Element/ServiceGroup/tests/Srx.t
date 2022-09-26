#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;

use PDK::Firewall::Element::Service::Srx;
use PDK::Firewall::Element::ServiceGroup::Srx;

my $serviceGroup;

ok(
  do {
    eval { $serviceGroup = PDK::Firewall::Element::ServiceGroup::Srx->new(fwId => 1, srvGroupName => 'a') };
    warn $@ if !!$@;
    $serviceGroup->isa('PDK::Firewall::Element::ServiceGroup::Srx');
  },
  ' 生成 PDK::Firewall::Element::ServiceGroup::Srx 对象'
);

ok(
  do {
    eval { $serviceGroup = PDK::Firewall::Element::ServiceGroup::Srx->new(fwId => 1, srvGroupName => 'a') };
    warn $@ if !!$@;
    $serviceGroup->sign eq 'a';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $serviceGroup = PDK::Firewall::Element::ServiceGroup::Srx->new(fwId => 1, srvGroupName => 'a');
      my $service = PDK::Firewall::Element::Service::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559',
        term     => 'z'
      );
      my $service1 = PDK::Firewall::Element::Service::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'e',
        srcPort  => 'c',
        dstPort  => '2525-2559',
        term     => 'z'
      );
      my $serviceGroup1 = PDK::Firewall::Element::ServiceGroup::Srx->new(fwId => 1, srvGroupName => 'b');
      $serviceGroup1->addSrvGroupMember('la', $service1);
      $serviceGroup->addSrvGroupMember('abc');
      $serviceGroup->addSrvGroupMember('def', $service);
      $serviceGroup->addSrvGroupMember('ghi', $serviceGroup1);
    };
    warn $@ if !!$@;
    exists $serviceGroup->srvGroupMembers->{'abc'}
      and not defined $serviceGroup->srvGroupMembers->{'abc'}
      and $serviceGroup->srvGroupMembers->{def}->isa('PDK::Firewall::Element::Service::Srx')
      and $serviceGroup->srvGroupMembers->{ghi}->isa('PDK::Firewall::Element::ServiceGroup::Srx')
      and $serviceGroup->dstPortRangeMap->{b}->min == 1525
      and $serviceGroup->dstPortRangeMap->{b}->max == 1559
      and $serviceGroup->dstPortRangeMap->{e}->min == 2525
      and $serviceGroup->dstPortRangeMap->{e}->max == 2559;
  },
  " addSrvGroupMember"
);

done_testing;
