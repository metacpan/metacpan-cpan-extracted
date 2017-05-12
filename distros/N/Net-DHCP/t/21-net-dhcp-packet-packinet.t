#!/usr/bin/perl -wT

use Test::More tests => 39;

BEGIN { use_ok( 'Net::DHCP::Packet' ); }
BEGIN { use_ok( 'Net::DHCP::Constants' ); }

use strict;

my $pac1 = "\0\0\0\0";
my $pac2 = "\1\2\3\4";
my $pac3 = "\1\2\3\4\5\6";
my $pac4 = "\1\2";
my $pac5 = "\1\2\0\0";

my $ip1 = "0.0.0.0";
my $ip2 = "1.2.3.4";
my $ip3 = "1.2.3.4.5.6";
my $ip4 = " 1 . 2 . 3 . \t4 ";
my $ip5 = "1.2.0.0";

is( packinet($ip1), $pac1, 'packinet 1');
is( packinet($ip2), $pac2 ,'packinet 2');
is( packinet($ip3), $pac2);
is( packinet($ip4), $pac1);
is( packinet(undef), $pac1);
is( packinet(q||), $pac1);
is( packinet(0), $pac1);
is( packinet(0x04030201), $pac1);

is( unpackinet($pac1), $ip1, 'unpackinet');
is( unpackinet($pac2), $ip2);
is( unpackinet($pac3), $ip1);
is( unpackinet($pac4), $ip1);
is( unpackinet(undef), $ip1);
is( unpackinet(q||), $ip1);
is( unpackinet(0), $ip1);
is( unpackinet(0x04030201), $ip1);

is( packinets("$ip1 $ip1"), $pac1.$pac1, "packinets");
is( packinets("$ip2 $ip5"), $pac2.$pac5);
is( packinets("$ip1,$ip2;$ip1/$ip2\t$ip1;;;$ip2"), $pac1.$pac2.$pac1.$pac2.$pac1.$pac2);
is( packinets($ip1), $pac1);
is( packinets($ip2), $pac2);
is( packinets($ip3), $pac2);
is( packinets($ip4), $pac1 x 8);
is( packinets($ip5), $pac5);
is( packinets(undef), $pac1,'packinets undef returns 0.0.0.0');
is( packinets(''), $pac1,'packinets "" returns 0.0.0.0');
is( packinets(0), $pac1,'0 goes to 0.0.0.0');

is( unpackinets($pac1), $ip1, "unpackinets");
is( unpackinets($pac2), $ip2);
is( unpackinets($pac3), "$ip2 $ip1");
is( unpackinets($pac4), $ip1);
is( unpackinets(undef), $ip1);
is( unpackinets(''), $ip1);
is( unpackinets(0), $ip1);
is( unpackinets(0x04030201), '54.55.51.48 53.57.56.53'); # decimal value 67305985

my @arr;
@arr = Net::DHCP::Packet::unpackinets_array($pac3);
is_deeply( \@arr, [$ip2, $ip1], 'unpackinets_array');

@arr = ($ip2, $ip5);
is( Net::DHCP::Packet::packinets_array(@arr), $pac2.$pac5, 'packinets_array');

