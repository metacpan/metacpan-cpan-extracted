#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;

use PDK::Firewall::Element::ProtocolGroup::Asa;

my $protocolGroup;

ok(
  do {
    eval { $protocolGroup = PDK::Firewall::Element::ProtocolGroup::Asa->new(fwId => 1, proGroupName => 'a') };
    warn $@ if !!$@;
    $protocolGroup->isa('PDK::Firewall::Element::ProtocolGroup::Asa');
  },
  ' 生成 PDK::Firewall::Element::ProtocolGroup::Asa 对象'
);

ok(
  do {
    eval { $protocolGroup = PDK::Firewall::Element::ProtocolGroup::Asa->new(fwId => 1, proGroupName => 'a') };
    warn $@ if !!$@;
    $protocolGroup->sign eq 'a';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $protocolGroup = PDK::Firewall::Element::ProtocolGroup::Asa->new(fwId => 1, proGroupName => 'a');
      my $protocol       = PDK::Firewall::Element::Protocol::Asa->new(fwId => 1, protocol => 'd');
      my $protocol1      = PDK::Firewall::Element::Protocol::Asa->new(fwId => 1, protocol => 'c');
      my $protocolGroup1 = PDK::Firewall::Element::ProtocolGroup::Asa->new(fwId => 1, proGroupName => 'b');
      $protocolGroup1->addProGroupMember('la', $protocol1);
      $protocolGroup->addProGroupMember('abc');
      $protocolGroup->addProGroupMember('def', $protocol);
      $protocolGroup->addProGroupMember('ghi', $protocolGroup1);
    };
    warn $@ if !!$@;
    exists $protocolGroup->proGroupMembers->{'abc'}
      and not defined $protocolGroup->proGroupMembers->{'abc'}
      and $protocolGroup->proGroupMembers->{'def'}->isa('PDK::Firewall::Element::Protocol::Asa')
      and $protocolGroup->proGroupMembers->{'ghi'}->isa('PDK::Firewall::Element::ProtocolGroup::Asa')
      and $protocolGroup->protocols->{'c'}->protocol eq 'c'
      and $protocolGroup->protocols->{'d'}->protocol eq 'd';
  },
  " addProGroupMember"
);
