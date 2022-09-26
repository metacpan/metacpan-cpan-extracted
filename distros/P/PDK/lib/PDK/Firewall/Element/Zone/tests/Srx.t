#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 2;
use Mojo::Util qw(dumper);

use PDK::Firewall::Element::Interface::Srx;
use PDK::Firewall::Element::Zone::Srx;
use PDK::Firewall::Element::Route::Srx;

my $zone;

ok(
  do {
    eval {
      $zone = PDK::Firewall::Element::Zone::Srx->new(fwId => 1, name => 'trust');
      my $interface = PDK::Firewall::Element::Interface::Srx->new(
        fwId          => 1,
        name          => 'reth0.0',
        interfaceType => 'layer3',
        ipAddress     => '10.15.254.38',
        mask          => '29'
      );
      my $route = PDK::Firewall::Element::Route::Srx->new(
        fwId    => $interface->fwId,
        network => $interface->ipAddress,
        mask    => $interface->mask
      );
      $interface->addRoute($route);
      $zone->addInterface($interface);
      print dumper $zone;
    };
    warn $@ if !!$@;
    $zone->isa('PDK::Firewall::Element::Zone::Srx');
  },
  ' 生成 PDK::Firewall::Element::Zone::Srx 对象'
);

ok(
  do {
    eval { $zone = PDK::Firewall::Element::Interface::Srx->new(fwId => 1, name => 'trust'); };
    warn $@ if $@;
    $zone->sign eq 'trust';
  },
  ' lazy生成 sign'
);

