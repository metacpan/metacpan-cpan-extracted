#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;

use PDK::Firewall::Element::Service::Asa;
my $service;

ok(
  do {
    eval { $service = PDK::Firewall::Element::Service::Asa->new(fwId => 1, srvName => 'a', dstPort => '100', protocol => 'tcp'); };
    warn $@ if !!$@;
    $service->isa('PDK::Firewall::Element::Service::Asa');
  },
  ' 生成 PDK::Firewall::Element::Service::Asa 对象'
);

ok(
  do {
    eval { $service = PDK::Firewall::Element::Service::Asa->new(fwId => 1, srvName => 'a', dstPort => '100', protocol => 'tcp'); };
    warn $@ if !!$@;
    $service->sign eq 'a';
  },
  ' lazy生成 sign(有 srvName)'
);

ok(
  do {
    eval { $service = PDK::Firewall::Element::Service::Asa->new(fwId => 1, srvName => 'a', dstPort => '100', protocol => 'tcp'); };
    warn $@ if !!$@;
    $service->metas->{'a<|>tcp<|>0-65535<|>100'}->sign eq 'a<|>tcp<|>0-65535<|>100'
      and $service->dstPortRangeMap->{tcp}->min == 100
      and $service->dstPortRangeMap->{tcp}->max == 100;
  },
  " new( fwId => 1, dstPort => '100', protocol => 'tcp' )"
);

done_testing;
