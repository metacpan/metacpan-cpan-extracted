#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;
use Time::Local;

use PDK::Firewall::Element::Schedule::Hillstone;
my $schedule;
my $date;

ok(
  do {
    eval {
      $schedule = PDK::Firewall::Element::Schedule::Hillstone->new(fwId => 1, schName => 'a', startDate => 'b', endDate => 'c');
    };
    warn $@ if !!$@;
    $schedule->isa('PDK::Firewall::Element::Schedule::Hillstone');
  },
  ' 生成 PDK::Firewall::Element::Schedule::Hillstone 对象'
);

ok(
  do {
    eval {
      $schedule = PDK::Firewall::Element::Schedule::Hillstone->new(fwId => 1, schName => 'a', startDate => 'b', endDate => 'c');
    };
    warn $@ if !!$@;
    $schedule->sign eq 'a';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $schedule = PDK::Firewall::Element::Schedule::Hillstone->new(
        fwId      => 1,
        schName   => 'a',
        startDate => '2013-09-24.00:00',
        endDate   => '2023-09-24.00:00'
      );
    };
    warn $@ if !!$@;
    $schedule->getSecondFromEpoch('2013-09-24.00:00') == 1379952000 ? 1 : 0;
  },
  q{ getSecondFromEpoch('2013-09-24.00:00')}
);

ok(
  do {
    eval {
      $schedule = PDK::Firewall::Element::Schedule::Hillstone->new(
        fwId      => 1,
        schName   => 'a',
        startDate => '2013-09-24.00:00',
        endDate   => '2023-09-24.00:00'
      );
    };
    warn $@ if !!$@;
    $schedule->createTimeRange;
    $schedule->{timeRange}{min} eq '1379952000' and $schedule->{timeRange}{max} eq '1695484800' ? 1 : 0;
  },
  q{ createTimeRange}
);

ok(
  do {
    $date = '2013-12-07 10:45:00 周六';
    my ($year, $mon, $mday, $hour, $min, $sec) = split('[\- :]', $date);
    my $time = timelocal($sec, $min, $hour, $mday, $mon - 1, $year - 1900);
    eval {
      $schedule = PDK::Firewall::Element::Schedule::Hillstone->new(
        fwId      => 1,
        schName   => 'a',
        startDate => '2013-09-24.00:00',
        endDate   => '2023-09-24.00:00'
      );
    };
    warn $@ if !!$@;
    $schedule->isEnable($time) == 1 ? 1 : 0;
  },
  qq{ date '$date' is valid on startDate => '10/10/2011 0:0', endDate => '3/31/2022 23:59'}
);

ok(
  do {
    $date = '2013-12-07 10:45:00 周六';
    my ($year, $mon, $mday, $hour, $min, $sec) = split('[\- :]', $date);
    my $time = timelocal($sec, $min, $hour, $mday, $mon - 1, $year - 1900);
    eval {
      $schedule = PDK::Firewall::Element::Schedule::Hillstone->new(
        fwId      => 1,
        schName   => 'a',
        startDate => '2013-09-24.00:00',
        endDate   => '2023-09-24.00:00'
      );
    };
    warn $@ if !!$@;
    $schedule->isExpired($time) == 0 ? 1 : 0;
  },
  qq{ date '$date' is not expired on startDate => '10/10/2011 0:0', endDate => '3/31/2022 23:59'}
);

done_testing;
