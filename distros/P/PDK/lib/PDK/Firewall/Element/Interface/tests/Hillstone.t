#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Printer;

use PDK::Firewall::Element::Interface::Hillstone;

my $interface;

ok(
  do {
    eval {
      $interface = PDK::Firewall::Element::Interface::Hillstone->new(
        fwId          => 1,
        name          => 'xxxx',
        ipAddress     => '192.168.8.1',
        mask          => '32',
        interfaceType => 'layer3',
        description   => 'yyyy'
      );
    };
    warn $@ if !!$@;
    $interface->isa('PDK::Firewall::Element::Interface::Hillstone');
  },
  ' 生成 PDK::Firewall::Element::Interface::Hillstone 对象'
);

ok(
  do {
    eval {
      $interface = PDK::Firewall::Element::Interface::Hillstone->new(
        fwId          => 1,
        name          => 'xxxx',
        ipAddress     => '192.168.8.1',
        mask          => '32',
        interfaceType => 'layer3',
        description   => 'yyyy'
      );
    };
    warn $@ if !!$@;
    $interface->sign eq 'xxxx';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $interface = PDK::Firewall::Element::Interface::Hillstone->new(
        fwId          => 1,
        name          => 'xxxx',
        ipAddress     => '192.168.8.1',
        mask          => '32',
        interfaceType => 'layer3',
        description   => 'yyyy'
      );
    };
    warn $@ if !!$@;
    $interface->range->isa('PDK::Utils::Set');
  },
  ' lazy生成 range'
);

done_testing;
