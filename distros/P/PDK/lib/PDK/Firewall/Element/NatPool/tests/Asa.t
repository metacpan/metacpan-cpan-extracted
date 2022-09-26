#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Printer;

use PDK::Firewall::Element::NatPool::Asa;

my $natPool;

ok(
  do {
    eval {
      $natPool = PDK::Firewall::Element::NatPool::Asa->new(
        fwId     => 1,
        poolIp   => '1.1.1.1',
        poolName => "xxxx",
        zone     => 'warnings firewall'
      );
    };
    warn $@ if !!$@;
    $natPool->isa('PDK::Firewall::Element::NatPool::Asa');
  },
  ' 生成 PDK::Firewall::Element::NatPool::Asa 对象'
);

ok(
  do {
    eval {
      $natPool = PDK::Firewall::Element::NatPool::Asa->new(
        fwId     => 1,
        poolIp   => '1.1.1.1',
        poolName => "xxxx",
        zone     => 'warnings firewall'
      );
    };
    warn $@ if !!$@;
    $natPool->sign eq 'xxxx';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $natPool = PDK::Firewall::Element::NatPool::Asa->new(
        fwId     => 1,
        poolIp   => '1.1.1.1',
        poolName => "xxxx",
        zone     => 'warnings firewall'
      );
    };
    warn $@ if !!$@;
    $natPool->poolRange->isa('PDK::Utils::Set');
  },
  ' lazy生成 poolRange'
);

done_testing;
