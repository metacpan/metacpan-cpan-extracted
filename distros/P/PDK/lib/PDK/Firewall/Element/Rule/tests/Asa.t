#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 11;
use Mojo::Util qw(dumper);

use PDK::Firewall::Element::Rule::Asa;
use PDK::Firewall::Element::Schedule::Asa;
use PDK::Firewall::Element::Address::Asa;
use PDK::Firewall::Element::Service::Asa;
use PDK::Firewall::Element::AddressGroup::Asa;
use PDK::Firewall::Element::ServiceGroup::Asa;
use PDK::Firewall::Element::Protocol::Asa;
use PDK::Firewall::Element::ProtocolGroup::Asa;

my $rule;

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
    };
    warn $@ if !!$@;
    $rule->isa('PDK::Firewall::Element::Rule::Asa');
  },
  ' 生成 PDK::Firewall::Element::Rule::Asa 对象'
);

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
    };
    warn $@ if !!$@;
    $rule->sign eq 'la<|>1';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
      $rule->setContent('lele');
    };
    warn $@ if !!$@;
    $rule->content eq 'lele';
  },
  " setContent('lele')"
);

ok(
  do {
    my $content = 'lele';
    my $add     = 'lala';
    eval {
      $rule = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => $content
      );
      $rule->addConfig($add);
    };
    warn $@ if !!$@;
    $rule->content eq $content . $add ? 1 : 0;
  },
  " addConfig('lelelala')"
);

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
      my $address      = PDK::Firewall::Element::Address::Asa->new(fwId => 1, ip => '10.11.77.41', mask => '255.255.252.0');
      my $addressGroup = PDK::Firewall::Element::AddressGroup::Asa->new(fwId => 1, addrGroupName => 'ghi');
      $rule->addSrcAddressMembers('abc');
      $rule->addSrcAddressMembers('def', $address);
      $rule->addSrcAddressMembers('ghi', $addressGroup);
    };
    warn $@ if !!$@;
    exists $rule->srcAddressMembers->{'abc'}
      and not defined $rule->srcAddressMembers->{'abc'}
      and $rule->srcAddressMembers->{'def'}->isa('PDK::Firewall::Element::Address::Asa')
      and $rule->srcAddressMembers->{'ghi'}->isa('PDK::Firewall::Element::AddressGroup::Asa');
  },
  " addSrcAddressMembers"
);

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
      my $address      = PDK::Firewall::Element::Address::Asa->new(fwId => 1, ip => '10.11.77.41', mask => '255.255.252.0');
      my $addressGroup = PDK::Firewall::Element::AddressGroup::Asa->new(fwId => 1, addrGroupName => 'ghi');
      $rule->addDstAddressMembers('abc');
      $rule->addDstAddressMembers('def', $address);
      $rule->addDstAddressMembers('ghi', $addressGroup);
    };
    warn $@ if !!$@;
    exists $rule->dstAddressMembers->{'abc'}
      and not defined $rule->dstAddressMembers->{'abc'}
      and $rule->dstAddressMembers->{'def'}->isa('PDK::Firewall::Element::Address::Asa')
      and $rule->dstAddressMembers->{'ghi'}->isa('PDK::Firewall::Element::AddressGroup::Asa');
  },
  " addDstAddressMembers"
);

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
      my $service = PDK::Firewall::Element::Service::Asa->new(fwId => 1, srvName => 'la', dstPort => '100', protocol => 'tcp');
      my $serviceGroup = PDK::Firewall::Element::ServiceGroup::Asa->new(fwId => 1, srvGroupName => 'a', protocol => 't');
      $rule->addServiceMembers('abc');
      $rule->addServiceMembers('def', $service);
      $rule->addServiceMembers('ghi', $serviceGroup);
    };
    warn $@ if !!$@;
    exists $rule->serviceMembers->{'abc'}
      and not defined $rule->serviceMembers->{'abc'}
      and $rule->serviceMembers->{'def'}->isa('PDK::Firewall::Element::Service::Asa')
      and $rule->serviceMembers->{'ghi'}->isa('PDK::Firewall::Element::ServiceGroup::Asa');
  },
  " addServiceMembers"
);

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
      my $protocol      = PDK::Firewall::Element::Protocol::Asa->new(fwId => 1, protocol => 'd');
      my $protocolGroup = PDK::Firewall::Element::ProtocolGroup::Asa->new(fwId => 1, proGroupName => 'a');
      $rule->addProtocolMembers('abc');
      $rule->addProtocolMembers('def', $protocol);
      $rule->addProtocolMembers('ghi', $protocolGroup);
    };
    warn $@ if !!$@;
    exists $rule->protocolMembers->{'abc'}
      and not defined $rule->protocolMembers->{'abc'}
      and $rule->protocolMembers->{'def'}->isa('PDK::Firewall::Element::Protocol::Asa')
      and $rule->protocolMembers->{'ghi'}->isa('PDK::Firewall::Element::ProtocolGroup::Asa');
  },
  " addProtocolMembers"
);

ok(
  do {
    my $time;
    eval {
      $rule = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala',
        schname       => 'a'
      );
      my $date = '2013-12-07 10:45:00 周六';
      my ($year, $mon, $mday, $hour, $min, $sec) = split('[\- :]', $date);
      $time = timelocal($sec, $min, $hour, $mday, $mon - 1, $year - 1900);
      my $schedule = PDK::Firewall::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'absolute',
        startDate => '00:00 01 November 2009',
        endDate   => '23:59 30 November 2012'
      );
      $rule->setSchedule($schedule);
    };
    warn $@ if !!$@;
    $rule->hasSchedule and $rule->schedule->isExpired($time);
  },
  " hasSchedule and setSchedule"
);

ok(
  do {
    my ($rule1, $rule2, $rule3);
    eval {
      $rule = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala',
        schname       => 'a'
      );
      $rule1 = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala',
        schname       => 'a'
      );
      my $schedule = PDK::Firewall::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'absolute',
        startDate => '00:00 01 November 2009',
        endDate   => '23:59 30 November 2013'
      );
      $rule1->setSchedule($schedule);
      $rule2 = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala',
        schname       => 'a'
      );
      $rule2->setIsDisable('inactive');
      $rule3 = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala',
        schname       => 'a'
      );
      $rule3->setSchedule($schedule);
      $rule3->setIsDisable('inactive');
    };
    warn $@ if !!$@;
    not $rule->ignore and $rule1->ignore and $rule2->ignore and $rule3->ignore;
  },
  " ignore"
);

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
    };
    warn $@ if !!$@;
          $rule->srcAddressGroup->isa('PDK::Firewall::Element::AddressGroup::Asa')
      and $rule->srcAddressGroup->addrGroupName eq '^'
      and $rule->dstAddressGroup->isa('PDK::Firewall::Element::AddressGroup::Asa')
      and $rule->dstAddressGroup->addrGroupName eq '^'
      and $rule->serviceGroup->isa('PDK::Firewall::Element::ServiceGroup::Asa')
      and $rule->serviceGroup->srvGroupName eq '^'
      and $rule->protocolGroup->isa('PDK::Firewall::Element::ProtocolGroup::Asa')
      and $rule->protocolGroup->proGroupName eq '^';
  },
  " lazy 生成 srcAddressGroup dstAddressGroup serviceGroup protocolGroup"
);
