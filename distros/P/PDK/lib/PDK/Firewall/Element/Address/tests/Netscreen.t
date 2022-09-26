#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Printer;

use PDK::Firewall::Element::Address::Netscreen;

my $address;

ok(
  do {
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
    };
    warn $@ if !!$@;
    $address->isa('PDK::Firewall::Element::Address::Netscreen');
  },
  ' 生成 PDK::Firewall::Element::Address::Netscreen 对象'
);

ok(
  do {
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
    };
    warn $@ if !!$@;
    p $address->sign;
    $address->sign eq 'yyyy<|>xxxx';
  },
  ' lazy生成 sign'
);

ok(
  do {
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
    };
    warn $@ if !!$@;
    my $range = PDK::Utils::Ip->getRangeFromIpMask('192.168.8.1', 32);
    $address->range->min eq $range->min and $address->range->max eq $range->max;
  },
  ' lazy生成 range'
);

ok(
  do {
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
    };
    warn $@ if !!$@;
    $address->addMember({ipmask => '192.168.8.2/32'});
    my $range1 = $address->range;
    my $ipSet  = PDK::Utils::Ip->new->getRangeFromIpMask('192.168.8.1', 32);
    $ipSet->mergeToSet(PDK::Utils::Ip->new->getRangeFromIpMask('192.168.8.2', 32));
    $range1->min eq $ipSet->min and $range1->max eq $ipSet->max;
  },
  ' addMember ipmask 方法'
);

ok(
  do {
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
    };
    warn $@ if !!$@;
    $address->addMember({range => '192.168.8.2-192.168.8.10'});
    my $range1 = $address->range;
    my $ipSet  = PDK::Utils::Ip->new->getRangeFromIpMask('192.168.8.1', 32);
    $ipSet->mergeToSet(PDK::Utils::Ip->new->getRangeFromIpMask('192.168.8.2', 32));
    $range1->min ge $ipSet->min and $range1->max ge $ipSet->max;
  },
  ' addMember range 方法'
);

ok(
  do {
    my $address1;
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
      $address1 = PDK::Firewall::Element::Address::Netscreen->new(
        fwId        => 1,
        addrName    => 'xxxx',
        ip          => '192.168.8.100',
        mask        => '30',
        zone        => 'yyyy',
        type        => 'mojo',
        description => 'xxxx',
      );
    };
    warn $@ if !!$@;
    $address->addMember({obj => $address1});
    $address->range->length == 2 and $address->range->max == 3232237671 and $address->range->min == 3232237569;
  },
  ' addMember obj 方法'
);

done_testing;
