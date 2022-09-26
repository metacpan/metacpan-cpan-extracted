#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 14;
use Mojo::Util qw(dumper);

use Time::Local;
use PDK::Firewall::Element::Schedule::Srx;
use PDK::Firewall::Element::Rule::Srx;
use PDK::Firewall::Element::Address::Srx;
use PDK::Firewall::Element::Service::Srx;
use PDK::Firewall::Element::AddressGroup::Srx;

my $rule;

ok(
  do {
    eval {
      $rule
        = PDK::Firewall::Element::Rule::Srx->new(fwId => 1, ruleName => '2', fromZone => 'a', toZone => 'b', content => 'lala');
    };
    warn $@ if !!$@;
    $rule->isa('PDK::Firewall::Element::Rule::Srx');
  },
  ' 生成 PDK::Firewall::Element::Rule::Srx 对象'
);

ok(
  do {
    eval {
      $rule
        = PDK::Firewall::Element::Rule::Srx->new(fwId => 1, ruleName => '2', fromZone => 'a', toZone => 'b', content => 'lala');
    };
    warn $@ if !!$@;
    $rule->sign eq 'a<|>b<|>2';
  },
  ' lazy生成 sign'
);

ok(
  do {
    my $content = 'lele';
    my $add     = 'lala';
    eval {
      $rule
        = PDK::Firewall::Element::Rule::Srx->new(fwId => 1, ruleName => '2', fromZone => 'a', toZone => 'b', content => $content);
      $rule->addConfig($add);
    };
    warn $@ if !!$@;
    $rule->content eq $content . $add;
  },
  " addConfig('lelelala')"
);

for my $attr (qw/ action schName hasLog isDisable content /) {
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
    eval {
      $rule
        = PDK::Firewall::Element::Rule::Srx->new(fwId => 1, ruleName => '2', fromZone => 'a', toZone => 'b', content => 'lala');
      my $address
        = PDK::Firewall::Element::Address::Srx->new(fwId => 1, addrName => 'a', ip => '10.11.77.41', mask => 22, zone => 'o');
      my $addressGroup = PDK::Firewall::Element::AddressGroup::Srx->new(fwId => 1, addrGroupName => 'a', zone => 'o');
      $rule->addSrcAddressMembers('abc');
      $rule->addSrcAddressMembers('def', $address);
      $rule->addSrcAddressMembers('ghi', $addressGroup);
    };
    warn $@ if !!$@;
    exists $rule->srcAddressMembers->{'abc'}
      and not defined $rule->srcAddressMembers->{'abc'}
      and $rule->srcAddressMembers->{'def'}->isa('PDK::Firewall::Element::Address::Srx')
      and $rule->srcAddressMembers->{'ghi'}->isa('PDK::Firewall::Element::AddressGroup::Srx');
  },
  " addSrcAddressMembers"
);

ok(
  do {
    eval {
      $rule
        = PDK::Firewall::Element::Rule::Srx->new(fwId => 1, ruleName => '2', fromZone => 'a', toZone => 'b', content => 'lala');
      my $address
        = PDK::Firewall::Element::Address::Srx->new(fwId => 1, addrName => 'a', ip => '10.11.77.41', mask => 22, zone => 'o');
      my $addressGroup = PDK::Firewall::Element::AddressGroup::Srx->new(fwId => 1, addrGroupName => 'a', zone => 'o');
      $rule->addDstAddressMembers('abc');
      $rule->addDstAddressMembers('def', $address);
      $rule->addDstAddressMembers('ghi', $addressGroup);
    };
    warn $@ if !!$@;
    exists $rule->dstAddressMembers->{'abc'}
      and not defined $rule->dstAddressMembers->{'abc'}
      and $rule->dstAddressMembers->{'def'}->isa('PDK::Firewall::Element::Address::Srx')
      and $rule->dstAddressMembers->{'ghi'}->isa('PDK::Firewall::Element::AddressGroup::Srx');
  },
  " addDstAddressMembers"
);

ok(
  do {
    eval {
      $rule
        = PDK::Firewall::Element::Rule::Srx->new(fwId => 1, ruleName => '2', fromZone => 'a', toZone => 'b', content => 'lala');
      my $service = PDK::Firewall::Element::Service::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559',
        term     => 'z'
      );
      my $serviceGroup = PDK::Firewall::Element::ServiceGroup::Srx->new(fwId => 1, srvGroupName => 'a');
      $rule->addServiceMembers('abc');
      $rule->addServiceMembers('def', $service);
      $rule->addServiceMembers('ghi', $serviceGroup);
    };
    warn $@ if !!$@;
    exists $rule->serviceMembers->{'abc'}
      and not defined $rule->serviceMembers->{'abc'}
      and $rule->serviceMembers->{'def'}->isa('PDK::Firewall::Element::Service::Srx')
      and $rule->serviceMembers->{'ghi'}->isa('PDK::Firewall::Element::ServiceGroup::Srx');
  },
  " addServiceMembers"
);

ok(
  do {
    my $time;
    eval {
      $rule = PDK::Firewall::Element::Rule::Srx->new(
        fwId     => 1,
        ruleName => '2',
        fromZone => 'a',
        toZone   => 'b',
        content  => 'lala',
        schname  => 'a'
      );
      my $date = '2013-12-07 10:45:00 周六';
      my ($year, $mon, $mday, $hour, $min, $sec) = split('[\- :]', $date);
      $time = timelocal($sec, $min, $hour, $mday, $mon - 1, $year - 1900);
      my $schedule = PDK::Firewall::Element::Schedule::Srx->new(
        fwId      => 1,
        schName   => 'a',
        startDate => '2011-09-24.00:00',
        endDate   => '2013-09-24.00:00'
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
      $rule = PDK::Firewall::Element::Rule::Srx->new(
        fwId     => 1,
        ruleName => '2',
        fromZone => 'a',
        toZone   => 'b',
        content  => 'lala',
        schname  => 'a'
      );
      $rule1 = PDK::Firewall::Element::Rule::Srx->new(
        fwId     => 1,
        ruleName => '2',
        fromZone => 'a',
        toZone   => 'b',
        content  => 'lala',
        schname  => 'a'
      );
      my $schedule = PDK::Firewall::Element::Schedule::Srx->new(
        fwId      => 1,
        schName   => 'a',
        startDate => '2011-09-24.00:00',
        endDate   => '2013-09-24.00:00'
      );
      $rule1->setSchedule($schedule);
      $rule2 = PDK::Firewall::Element::Rule::Srx->new(
        fwId     => 1,
        ruleName => '2',
        fromZone => 'a',
        toZone   => 'b',
        content  => 'lala',
        schname  => 'a'
      );
      $rule2->setIsDisable('deactivate');
      $rule3 = PDK::Firewall::Element::Rule::Srx->new(
        fwId     => 1,
        ruleName => '2',
        fromZone => 'a',
        toZone   => 'b',
        content  => 'lala',
        schname  => 'a'
      );
      $rule3->setSchedule($schedule);
      $rule3->setIsDisable('deactivate');

    };
    warn $@ if !!$@;
    not $rule->ignore and $rule1->ignore and $rule2->ignore and $rule3->ignore;
  },
  " ignore"
);

ok(
  do {
    eval {
      $rule = PDK::Firewall::Element::Rule::Srx->new(
        fwId     => 1,
        ruleName => '2',
        fromZone => 'a',
        toZone   => 'b',
        content  => 'lala',
        schname  => 'a'
      );
    };
    warn $@ if !!$@;
          $rule->srcAddressGroup->isa('PDK::Firewall::Element::AddressGroup::Srx')
      and $rule->srcAddressGroup->addrGroupName eq '^'
      and $rule->srcAddressGroup->zone eq '^'
      and $rule->dstAddressGroup->isa('PDK::Firewall::Element::AddressGroup::Srx')
      and $rule->dstAddressGroup->addrGroupName eq '^'
      and $rule->dstAddressGroup->zone eq '^'
      and $rule->serviceGroup->isa('PDK::Firewall::Element::ServiceGroup::Srx')
      and $rule->serviceGroup->srvGroupName eq '^';
  },
  " lazy 生成 srcAddressGroup dstAddressGroup serviceGroup"
);
