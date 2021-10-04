#!/usr/bin/env perl
use 5.016;
use warnings;
use Test::Simple tests => 10;

use Netstack::Utils::Ip;

my $ip;

ok(
  do {
    eval { $ip = Netstack::Utils::Ip->new };
    warn $@ if $@;
    $ip->isa('Netstack::Utils::Ip');
  },
  ' 生成 Netstack::Utils::Ip 对象'
);

ok(
  do {
    eval { $ip = Netstack::Utils::Ip->new };
    warn $@ if $@;
    $ip->changeIpToInt('10.11.77.41') == 168512809;
  },
  ' changeIpToInt'
);

ok(
  do {
    eval { $ip = Netstack::Utils::Ip->new };
    warn $@ if $@;
    $ip->changeIntToIp(168512809) eq '10.11.77.41';
  },
  ' changeIntToIp'
);

ok(
  do {
    eval { $ip = Netstack::Utils::Ip->new };
    warn $@ if $@;
    $ip->changeMaskToNumForm('255.255.252.0') == 22
      and $ip->changeMaskToNumForm(22) == 22;
  },
  ' changeMaskToNumForm'
);

ok(
  do {
    eval { $ip = Netstack::Utils::Ip->new };
    warn $@ if $@;
    $ip->changeMaskToIpForm('255.255.252.0') eq '255.255.252.0'
      and $ip->changeMaskToIpForm(22) eq '255.255.252.0';
  },
  ' changeMaskToIpForm'
);

ok(
  do {
    eval { $ip = Netstack::Utils::Ip->new };
    warn $@ if $@;
    my ( $min, $max ) = $ip->getRangeFromIpMask( '10.11.77.41', 22 );
    my $range = $ip->getRangeFromIpMask( '10.11.77.41', '255.255.252.0' );
          $range->min == $min
      and $min == 168512512
      and $range->max == $max
      and $max == 168513535;
  },
  ' getRangeFromIpMask'
);

ok(
  do {
    eval { $ip = Netstack::Utils::Ip->new };
    warn $@ if $@;
    my ( $min, $max ) = $ip->getRangeFromIpRange( '10.11.77.40', '10.11.77.41' );
    my $range = $ip->getRangeFromIpRange( '10.11.77.41', '10.11.77.40' );
          $range->min == $min
      and $min == 168512808
      and $range->max == $max
      and $max == 168512809;
  },
  ' getRangeFromIpRange'
);

ok(
  do {
    eval { $ip = Netstack::Utils::Ip->new };
    warn $@ if $@;
    my $netIp = $ip->getNetIpFromIpMask( "10.11.77.41", 27 );
    $netIp eq "10.11.77.32";
  },
  ' getNetIpFromIpMask'
);

ok(
  do {
    eval { $ip = Netstack::Utils::Ip->new };
    warn $@ if $@;
    my $netIp = $ip->getIpMaskFromRange( 168558592, 168574975 );
    $netIp eq "10.12.0.0/18";
  },
  ' getIpMaskFromRange'
);

ok(
  do {
    eval { $ip = Netstack::Utils::Ip->new };
    warn $@ if $@;
    my $mask = $ip->changeWildcardToMaskForm('0.0.255.255');
    $mask eq "255.255.0.0";
  },
  'changeWildcardToMaskForm'
);
