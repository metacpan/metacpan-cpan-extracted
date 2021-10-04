#!/usr/bin/env perl
use 5.016;
use warnings;
use Test::Simple tests => 2;

use Netstack::Utils::Date;

my $date;

ok(
  do {
    eval { $date = Netstack::Utils::Date->new };
    warn $@ if $@;
    $date->isa('Netstack::Utils::Date');
  },
  ' 生成 Netstack::Utils::Date 对象'
);

ok(
  do {
    eval { $date = Netstack::Utils::Date->new };
    warn $@ if $@;
    my $time = 1587431015;
    say $date->getLocalDate($time);
    say $date->getLocalDate();
  },
  ' getLocalDate 测试生成时间'
);
