#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 12;
use Time::Local;

use PDK::Firewall::Element::Rule::Netscreen;
use PDK::Firewall::Element::Schedule::Netscreen;
use PDK::Firewall::Element::Address::Netscreen;
use PDK::Firewall::Element::Service::Netscreen;
use PDK::Firewall::Element::AddressGroup::Netscreen;
use PDK::Firewall::Element::ServiceGroup::Netscreen;

my $rule;

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
    };
    warn $@ if !!$@;
    $rule->isa('PDK::Firewall::Element::Rule::Netscreen');
  },
  ' 生成 PDK::Firewall::Element::Rule::Netscreen 对象'
);

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
    };
    warn $@ if !!$@;
    $rule->sign eq '2';
  },
  ' lazy生成 sign'
);

for my $attr (qw/ hasApplicationCheck isDisable content /) {
  my $func   = "set" . ucfirst($attr);
  my $string = 'abcdefg';
  my $code   = <<_CODE_;
ok(
    do {
        eval {
            \$rule->$func('$string');
        };
        warn \$@ if \$@;
        \$rule->$attr eq '$string' ? 1 : 0;
    },
    " $func('$string')");
_CODE_
  eval($code);
  die $@ if !!$@;
}

ok(
  do {
    my $schedule;
    my $time;
    eval {
      $rule = PDK::Firewall::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234,
        schName  => 'a'
      );
      my $date = '2013-12-07 10:45:00 周六';
      my ($year, $mon, $mday, $hour, $min, $sec) = split('[\- :]', $date);
      $time     = timelocal($sec, $min, $hour, $mday, $mon - 1, $year - 1900);
      $schedule = PDK::Firewall::Element::Schedule::Netscreen->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'once',
        startDate => '10/10/2011 0:0',
        endDate   => '3/31/2022 23:59'
      );
      $rule->setSchedule($schedule);
    };
    warn $@ if !!$@;
    $rule->hasSchedule and not $rule->schedule->isExpired($time);
  },
  " hasSchedule and setSchedule"
);

ok(
  do {
    my ($rule1, $rule2, $rule3);
    eval {
      $rule = PDK::Firewall::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234,
        schName  => 'a'
      );
      my $schedule = PDK::Firewall::Element::Schedule::Netscreen->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'once',
        startDate => '10/10/2011 0:0',
        endDate   => '3/31/2012 23:59'
      );
      $rule1 = PDK::Firewall::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
      $rule1->setIsDisable('disable');
      $rule2 = PDK::Firewall::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234,
        schName  => 'a'
      );
      $rule2->setSchedule($schedule);
      $rule3 = PDK::Firewall::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234,
        schName  => 'a'
      );
      $rule3->setIsDisable('disable');
      $rule3->setSchedule($schedule);
    };
    warn $@ if !!$@;
    not $rule->ignore and $rule1->ignore and $rule2->ignore and $rule3->ignore;
  },
  " ignore"
);

ok(
  do {
    my $content = 'lele';
    my $add     = 'lala';
    eval {
      $rule = PDK::Firewall::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => $content,
        priority => 234
      );
      $rule->addConfig($add);
    };
    warn $@ if !!$@;
    $rule->content eq $content . $add;
  },
  " addConfig('lelelala')"
);

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
      my $address = PDK::Firewall::Element::Address::Netscreen->new(
        fwId     => 1,
        addrName => 'a',
        ip       => '10.11.77.41',
        mask     => '255.255.252.0',
        zone     => 'o'
      );
      my $addressGroup = PDK::Firewall::Element::AddressGroup::Netscreen->new(fwId => 1, addrGroupName => 'a', zone => 'o');
      $rule->addSrcAddressMembers('abc');
      $rule->addSrcAddressMembers('def', $address);
      $rule->addSrcAddressMembers('ghi', $addressGroup);
    };
    warn $@ if !!$@;
    exists $rule->srcAddressMembers->{'abc'}
      and not defined $rule->srcAddressMembers->{'abc'}
      and $rule->srcAddressMembers->{'def'}->isa('PDK::Firewall::Element::Address::Netscreen')
      and $rule->srcAddressMembers->{'ghi'}->isa('PDK::Firewall::Element::AddressGroup::Netscreen');
  },
  " addSrcAddressMembers"
);

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
      my $address = PDK::Firewall::Element::Address::Netscreen->new(
        fwId     => 1,
        addrName => 'a',
        ip       => '10.11.77.41',
        mask     => '255.255.252.0',
        zone     => 'o'
      );
      my $addressGroup = PDK::Firewall::Element::AddressGroup::Netscreen->new(fwId => 1, addrGroupName => 'a', zone => 'o');
      $rule->addDstAddressMembers('abc');
      $rule->addDstAddressMembers('def', $address);
      $rule->addDstAddressMembers('ghi', $addressGroup);
    };
    warn $@ if !!$@;
    exists $rule->dstAddressMembers->{'abc'}
      and not defined $rule->dstAddressMembers->{'abc'}
      and $rule->dstAddressMembers->{'def'}->isa('PDK::Firewall::Element::Address::Netscreen')
      and $rule->dstAddressMembers->{'ghi'}->isa('PDK::Firewall::Element::AddressGroup::Netscreen');
  },
  " addDstAddressMembers"
);

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
      my $service = PDK::Firewall::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
      my $serviceGroup = PDK::Firewall::Element::ServiceGroup::Netscreen->new(fwId => 1, srvGroupName => 'a');
      $rule->addServiceMembers('abc');
      $rule->addServiceMembers('def', $service);
      $rule->addServiceMembers('ghi', $serviceGroup);
    };
    warn $@ if !!$@;
    exists $rule->serviceMembers->{'abc'}
      and not defined $rule->serviceMembers->{'abc'}
      and $rule->serviceMembers->{'def'}->isa('PDK::Firewall::Element::Service::Netscreen')
      and $rule->serviceMembers->{'ghi'}->isa('PDK::Firewall::Element::ServiceGroup::Netscreen');
  },
  " addServiceMembers"
);

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
    };
    warn $@ if !!$@;
          $rule->srcAddressGroup->isa('PDK::Firewall::Element::AddressGroup::Netscreen')
      and $rule->srcAddressGroup->addrGroupName eq '^'
      and $rule->srcAddressGroup->zone eq '^'
      and $rule->dstAddressGroup->isa('PDK::Firewall::Element::AddressGroup::Netscreen')
      and $rule->dstAddressGroup->addrGroupName eq '^'
      and $rule->dstAddressGroup->zone eq '^'
      and $rule->serviceGroup->isa('PDK::Firewall::Element::ServiceGroup::Netscreen')
      and $rule->serviceGroup->srvGroupName eq '^';
  },
  " lazy 生成 srcAddressGroup dstAddressGroup serviceGroup"
);
