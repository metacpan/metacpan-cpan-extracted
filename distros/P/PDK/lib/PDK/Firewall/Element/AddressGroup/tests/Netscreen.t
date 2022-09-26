#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Printer;

use PDK::Firewall::Element::Address::Netscreen;
use PDK::Firewall::Element::AddressGroup::Netscreen;

my $addrGroup;

ok(
  do {
    eval {
      $addrGroup = PDK::Firewall::Element::AddressGroup::Netscreen->new(
        fwId          => 1,
        addrGroupName => 'zzz',
        zone          => 'xxx',
        description   => 'yyy'
      );
    };
    warn $@ if !!$@;
    $addrGroup->isa('PDK::Firewall::Element::AddressGroup::Netscreen');
  },
  ' 生成 PDK::Firewall::Element::AddressGroup::Netscreen 对象'
);

ok(
  do {
    eval {
      $addrGroup = PDK::Firewall::Element::AddressGroup::Netscreen->new(
        fwId          => 1,
        addrGroupName => 'zzz',
        zone          => 'xxx',
        description   => 'yyy'
      );
    };
    warn $@ if !!$@;
    p $addrGroup->sign;
    $addrGroup->sign eq 'xxx<|>zzz';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $addrGroup = PDK::Firewall::Element::AddressGroup::Netscreen->new(
        fwId          => 1,
        addrGroupName => 'zzz',
        zone          => 'xxx',
        description   => 'yyy'
      );
    };
    warn $@ if !!$@;
    $addrGroup->range->isa('PDK::Utils::Set');
  },
  ' lazy生成 range'
);

ok(
  do {
    my $address;
    eval {
      $address = PDK::Firewall::Element::Address::Netscreen->new(
        fwId        => 1,
        addrName    => 'xxxx',
        ip          => '192.168.8.1',
        mask        => '32',
        zone        => 'yyyy',
        type        => 'mojo',
        description => 'xxxx',
      );
      $addrGroup = PDK::Firewall::Element::AddressGroup::Netscreen->new(
        fwId          => 1,
        addrGroupName => 'zzz',
        zone          => 'xxx',
        description   => 'yyy'
      );
    };
    warn $@ if !!$@;
    $addrGroup->addAddrGroupMember("member1", $address);
    $addrGroup->range->min == 3232237569 and $addrGroup->range->max == 3232237569;
  },
  ' addAddrGroupMember 添加地址成员对象'
);

ok(
  do {
    my $address;
    my $addrGroup1;
    eval {
      $address = PDK::Firewall::Element::Address::Netscreen->new(
        fwId        => 1,
        addrName    => 'xxxx',
        ip          => '192.168.8.10',
        mask        => '32',
        zone        => 'yyyy',
        type        => 'mojo',
        description => 'xxxx',
      );
      $addrGroup = PDK::Firewall::Element::AddressGroup::Netscreen->new(
        fwId          => 1,
        addrGroupName => 'zzz',
        zone          => 'xxx',
        description   => 'yyy'
      );
      $addrGroup1 = PDK::Firewall::Element::AddressGroup::Netscreen->new(
        fwId          => 1,
        addrGroupName => 'mmm',
        zone          => 'nnn',
        description   => 'jjj'
      );
    };
    warn $@ if !!$@;
    $addrGroup->addAddrGroupMember("member1", $address);
    $addrGroup1->addAddrGroupMember("groupMember", $addrGroup);
    $addrGroup->range->min == 3232237578 and $addrGroup->range->max == 3232237578;
  },
  ' addAddrGroupMember 添加地址组成员对象'
);

ok(
  do {
    eval {
      $addrGroup = PDK::Firewall::Element::AddressGroup::Netscreen->new(
        fwId          => 1,
        addrGroupName => 'zzz',
        zone          => 'xxx',
        description   => 'yyy'
      );
    };
    warn $@ if !!$@;
    $addrGroup->addAddrGroupMember("nil", undef);
    keys %{$addrGroup->{addrGroupMembers}} == 0;
  },
  ' lazy生成 range'
);

done_testing;
