#!/usr/bin/env perl

BEGIN {
  if ($] ge '5.012') {
    use strict;
    use warnings;
  }
}

use lib '.';
use Net::IPAddress::Util qw( :constr );
use Net::IPAddress::Util::Range;
use Net::IPAddress::Util::Collection;
use Test::More tests => 49;

$Net::IPAddress::Util::DIE_ON_ERROR = 1;
$Net::IPAddress::Util::PROMOTE_N32 = 0;

{
  # diag('Pure IPv4');
  my $test = IP('192.168.0.1');
  my $nf = $test->normal_form();
  is($test->str() ,        '192.168.0.1', "Pure IPv4 round-trip via str()");
  is("$test"      ,        '192.168.0.1', "Pure IPv4 round-trip overloaded");
  is($test->ipv4(),        '192.168.0.1', "Pure IPv4 round-trip via ipv4()");
  is($test->ipv6(), '::ffff:192.168.0.1', "Pure IPv4 round-trip via ipv6()");
  is($nf          , '00000000000000000000ffffc0a80001', "Pure IPv4 round-trip normal form");
  is($test->as_n32(), '3232235521', "Pure IPv4 round-trip via as_n32()");
  is($test->as_n128(), '281473913978881', "Pure IPv4 round-trip via as_n128()");
}

{
  # diag('Pure IPv4 the other way around');
  my $test = IP('281473913978881');
  my $nf = $test->normal_form();
  is("$test"      ,        '192.168.0.1', "Pure IPv4 the other way around round-trip overloaded");
  is($nf          , '00000000000000000000ffffc0a80001', "Pure IPv4 the other way around round-trip normal form");
}

{
  # diag('IPv4-in-IPv6');
  my $test = IP('::ffff:192.168.0.1');
  my $nf = $test->normal_form();
  is("$test" , '192.168.0.1', "IPv4-in-IPv6 round-trip");
  is($nf , '00000000000000000000ffffc0a80001', "IPv4-in-IPv6 round-trip normal form");
}

{
  # diag('IPv4-as-IPv6');
  my $test = IP('::ffff:c0a8:1');
  my $nf = $test->normal_form();
  is("$test" , '192.168.0.1', "IPv4-as-IPv6 round-trip");
  is($nf , '00000000000000000000ffffc0a80001', "IPv4-as-IPv6 round-trip normal form");
}

{
  # diag('Pure IPv6');
  my $test = IP('12::34');
  my $nf = $test->normal_form();
  is("$test" , '12::34', "Pure IPv6 round-trip");
  is($nf , '00120000000000000000000000000034', "Pure IPv6 round-trip normal form");
}

{
  # diag('Pure IPv6 without a ::');
  my $test = IP('1:2:3:4:5:6:7:8');
  my $nf = $test->normal_form();
  is("$test" , '1:2:3:4:5:6:7:8', "Pure IPv6 without a :: round-trip");
  is($nf , '00010002000300040005000600070008', "Pure IPv6 without a :: round-trip normal form");
}

{
  # diag('RT 99174');
  my $test = IP('1:2::3:4');
  my $nf = $test->normal_form();
  is("$test" , '1:2::3:4', "RT 99174 round-trip");
  is($nf , '00010002000000000000000000030004', "RT 99174 round-trip normal form");
}

{
  # diag("Single IPv4 range");
  my $lower = IP('192.168.0.1');
  my $upper = IP('192.168.0.1');
  my $range = Net::IPAddress::Util::Range->new({ lower => $lower, upper => $upper });
  my $bounds = $range->outer_bounds();
  is("$range"              , '(192.168.0.1 .. 192.168.0.1)', "Single IPv4 range");
  is("$bounds->{ lower }"  , '192.168.0.1', "Single IPv4 base");
  is("$bounds->{ upper }"  , '192.168.0.1', "Single IPv4 highest");
  is("$bounds->{ netmask }", '255.255.255.255', "Single IPv4 netmask");
  is("$bounds->{ cidr }"   , '32', "Single IPv4 cidr");
}

{
  # diag("Single IPv6 range");
  my $lower = IP('12::34');
  my $upper = IP('12::34');
  my $range = Net::IPAddress::Util::Range->new({ lower => $lower, upper => $upper });
  my $bounds = $range->outer_bounds();
  is("$range"              , '(12::34 .. 12::34)', "Single IPv6 range");
  is("$bounds->{ lower }"  , '12::34', "Single IPv6 base");
  is("$bounds->{ upper }"  , '12::34', "Single IPv6 highest");
  is("$bounds->{ netmask }", 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', "Single IPv6 netmask");
  is("$bounds->{ cidr }"   , '128', "Single IPv6 cidr");
}

{
  # diag("Large IPv4 range");
  my $lower = IP('192.168.0.3');
  my $upper = IP('192.168.0.123');
  my $range = Net::IPAddress::Util::Range->new({ lower => $lower, upper => $upper });
  my $bounds = $range->outer_bounds();
  is("$range"              , '(192.168.0.3 .. 192.168.0.123)', "Large-range range");
  is("$bounds->{ lower }"  , '192.168.0.0', "Large-range base");
  is("$bounds->{ upper }"  , '192.168.0.127', "Large-range highest");
  is("$bounds->{ netmask }", '255.255.255.128', "Large-range netmask");
  is("$bounds->{ cidr }"   , '25', "Large-range cidr");
}
{
  # diag("Large IPv4 collection");
  my $lower = IP('192.168.0.3');
  # diag("l`$lower'");
  my $upper = IP('192.168.0.123');
  # diag("u`$upper'");
  my $range = Net::IPAddress::Util::Range->new({ lower => $lower, upper => $upper });
  # diag("$range");
  my $tight = $range->tight();
  # diag("$_") for @$tight;
  is(scalar(@{$tight}), 9, "Large-range tight size");
  my $compacted = $tight->compacted();
  # diag("done compacting");
  is(scalar(@{$compacted}), 1, "Large-range collection from tight, compacted");
  my $coll_t = $compacted->tight();
  is(scalar(@{$coll_t}), 9, "Round and round we go...");
  is(
    (join ', ', $coll_t->as_ranges),
    '(192.168.0.3 .. 192.168.0.3), (192.168.0.4 .. 192.168.0.7), (192.168.0.8 .. 192.168.0.15), (192.168.0.16 .. 192.168.0.31), (192.168.0.32 .. 192.168.0.63), (192.168.0.64 .. 192.168.0.95), (192.168.0.96 .. 192.168.0.111), (192.168.0.112 .. 192.168.0.119), (192.168.0.120 .. 192.168.0.123)',
    "Round and round we go... (as ranges)"
  );
  is(
    (join ', ', $coll_t->as_cidrs),
    '192.168.0.3/32, 192.168.0.4/30, 192.168.0.8/29, 192.168.0.16/28, 192.168.0.32/27, 192.168.0.64/27, 192.168.0.96/28, 192.168.0.112/29, 192.168.0.120/30',
    "Round and round we go... (as cidrs)"
  );
  is(
    (join ', ', $coll_t->as_netmasks),
    '192.168.0.3 (255.255.255.255), 192.168.0.4 (255.255.255.252), 192.168.0.8 (255.255.255.248), 192.168.0.16 (255.255.255.240), 192.168.0.32 (255.255.255.224), 192.168.0.64 (255.255.255.224), 192.168.0.96 (255.255.255.240), 192.168.0.112 (255.255.255.248), 192.168.0.120 (255.255.255.252)',
    "Round and round we go... (as netmasks)"
  );
}

{
  # diag("Single IPv4 range via 'ip' argument");
  my $range = Net::IPAddress::Util::Range->new({ ip => '192.168.0.1' });
  is("$range" , '(192.168.0.1 .. 192.168.0.1)', "Single IPv4 range via 'ip' argument");
}

{
  # diag("Single IPv4 range via cidrish 'ip' argument");
  my $range = Net::IPAddress::Util::Range->new({ ip => '192.168.0.1/32' });
  is("$range" , '(192.168.0.1 .. 192.168.0.1)', "Single IPv4 range via cidrish 'ip' argument");
}

{
  # diag("Single IPv6 range via cidrish 'ip' argument");
  my $range = Net::IPAddress::Util::Range->new({ ip => '1::1/128' });
  is("$range" , '(1::1 .. 1::1)', "Single IPv6 range via cidrish 'ip' argument");
}

{
  # diag("Large IPv6 range via cidrish 'ip' argument");
  my $range = Net::IPAddress::Util::Range->new({ ip => '1::/120' });
  is("$range" , '(1:: .. 1::ff)', "Large IPv6 range via cidrish 'ip' argument");
}

{
  # diag("Large IPv4 range via cidrish 'ip' argument");
  my $range = Net::IPAddress::Util::Range->new({ ip => '192.168.0.0/24' });
  is("$range" , '(192.168.0.0 .. 192.168.0.255)', "Large IPv4 range via cidrish 'ip' argument");
}

{
  # diag("Large IPv4 range via 'cidr' argument");
  my $range = Net::IPAddress::Util::Range->new({ ip => '192.168.0.0', cidr => '24' });
  is("$range" , '(192.168.0.0 .. 192.168.0.255)', "Large IPv4 range via 'cidr' argument");
}

{
  # diag("Large IPv4 range via 'netmask' argument");
  my $range = Net::IPAddress::Util::Range->new({ ip => '192.168.0.0', netmask => '255.255.255.0' });
  is("$range" , '(192.168.0.0 .. 192.168.0.255)', "Large IPv4 range via 'netmask' argument");
}

{
  # diag('PROMOTE_N32');
  local $Net::IPAddress::Util::PROMOTE_N32 = 1;
  my $ip = IP(3232235521);
  is("$ip", '192.168.0.1', 'PROMOTE_N32');
  is($ip->as_n32(), 3232235521, 'as_n32()');
}
