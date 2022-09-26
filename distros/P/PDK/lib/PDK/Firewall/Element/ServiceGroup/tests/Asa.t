#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Printer;

use PDK::Firewall::Element::Service::Asa;
use PDK::Firewall::Element::ServiceGroup::Asa;

my $serviceGroup;

ok(
  do {
    eval { $serviceGroup = PDK::Firewall::Element::ServiceGroup::Asa->new(fwId => 1, srvGroupName => 'a', protocol => 't'); };
    warn $@ if !!$@;
    $serviceGroup->isa('PDK::Firewall::Element::ServiceGroup::Asa');
  },
  ' 生成 PDK::Firewall::Element::ServiceGroup::Asa 对象'
);

ok(
  do {
    eval { $serviceGroup = PDK::Firewall::Element::ServiceGroup::Asa->new(fwId => 1, srvGroupName => 'a', protocol => 't'); };
    warn $@ if !!$@;
    $serviceGroup->sign eq 'a';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $serviceGroup = PDK::Firewall::Element::ServiceGroup::Asa->new(fwId => 1, srvGroupName => 'a', protocol => 't');
      my $service       = PDK::Firewall::Element::Service::Asa->new(fwId => 1, srvName => 'b', dstPort => '100', protocol => 'u');
      my $service1      = PDK::Firewall::Element::Service::Asa->new(fwId => 1, srvName => 'c', dstPort => '200', protocol => 'v');
      my $serviceGroup1 = PDK::Firewall::Element::ServiceGroup::Asa->new(fwId => 1, srvGroupName => 'b', protocol => 't');
      $serviceGroup1->addSrvGroupMember('la', $service1);
      $serviceGroup->addSrvGroupMember('abc');
      $serviceGroup->addSrvGroupMember('def', $service);
      $serviceGroup->addSrvGroupMember('ghi', $serviceGroup1);
    };
    warn $@ if !!$@;
    exists $serviceGroup->srvGroupMembers->{abc}
      and not defined $serviceGroup->srvGroupMembers->{abc}
      and $serviceGroup->srvGroupMembers->{def}->isa('PDK::Firewall::Element::Service::Asa')
      and $serviceGroup->srvGroupMembers->{ghi}->isa('PDK::Firewall::Element::ServiceGroup::Asa')
      and $serviceGroup->dstPortRangeMap->{u}->mins->[0] == 100
      and $serviceGroup->dstPortRangeMap->{u}->maxs->[0] == 100
      and $serviceGroup->dstPortRangeMap->{v}->mins->[0] == 200
      and $serviceGroup->dstPortRangeMap->{v}->maxs->[0] == 200;
  },
  " addSrvGroupMember"
);

done_testing;
