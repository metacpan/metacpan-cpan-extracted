use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use silktest;

use Test::More tests => 7;

use Net::Silk qw( :basic );

BEGIN { use_ok( SILK_IPWILDCARD_CLASS ) }

sub make_wc { new_ok(SILK_IPWILDCARD_CLASS, \@_ ) }

sub new_wc { SILK_IPWILDCARD_CLASS->new(shift) }

sub new_ip { SILK_IPADDR_CLASS->new(shift) }

###

sub test_construction {

  plan tests => 62;

  make_wc("0.0.0.0");
  make_wc("255.255.255.255");
  make_wc("     255.255.255.255");
  make_wc("255.255.255.255     ");
  make_wc("   255.255.255.255  ");
  make_wc("0.0.0.0/31");
  make_wc("255.255.255.254-255");
  make_wc("3,2,1.4.5.6");
  make_wc("0.0.0.1,31,51,71,91,101,121,141,161,181,211,231,251");
  make_wc("0,255.0,255.0,255.0,255");
  make_wc("1.1.128.0/22");
  make_wc("128.x.0.0");
  make_wc("128.0-255.0.0");
  make_wc("128.0,128-255,1-127.0.0");
  make_wc("128.0,128,129-253,255-255,254,1-127.0.0");
  make_wc("128.0,128-255,1-127.0.0  ");
  make_wc("  128.0,128-255,1-127.0.0  ");
  make_wc("  128.0,128-255,,1-127.0.0  ");
  make_wc(new_ip("1.2.3.4"));

  SKIP: {
    skip("ipv6 not enabled", 43) unless SILK_IPV6_ENABLED;
    make_wc("0:0:0:0:0:0:0:0");
    make_wc("::");
    make_wc("::0.0.0.0");
    make_wc("1:2:3:4:5:6:7:8");
    make_wc("1:203:405:607:809:a0b:c0d:e0f");
    make_wc("1:203:405:607:809:a0b:12.13.14.15");
    make_wc("::FFFF");
    make_wc("::FFFF:FFFF");
    make_wc("::0.0.255.255");
    make_wc("::255.255.255.255");
    make_wc("FFFF::");
    make_wc("0,FFFF::0,FFFF");
    make_wc("::FFFF:0,10.0.0.0,10");
    make_wc("::FFFF:0.0,160.0,160.0");
    make_wc("0:0:0:0:0:0:0:0/127");
    make_wc("::/127");
    make_wc("0:0:0:0:0:0:0:0/110");
    make_wc("0:0:0:0:0:0:0:0/95");
    make_wc("0:ffff::0/127");
    make_wc("0:ffff::0.0.0.0,1");
    make_wc("0:ffff::0.0.0.0-10");
    make_wc("0:ffff::0.0.0.x");
    make_wc("::ffff:0:0:0:0:0:0/110");
    make_wc("0:ffff::/112");
    make_wc("0:ffff:0:0:0:0:0:x");
    make_wc("0:ffff:0:0:0:0:0:x");
    make_wc("0:ffff:0:0:0:0:0:0-ffff");
    make_wc("0:ffff:0:0:0:0:0.0.x.x");
    make_wc("0:ffff:0:0:0:0:0.0.0-255.128-254,0-126,255,127");
    make_wc("0:ffff:0:0:0:0:0.0.128-254,0-126,255,127.x");
    make_wc("0:ffff:0:0:0:0:0.0.0.0/112");
    make_wc("0:ffff:0:0:0:0:0.0,1.x.x");
    make_wc("0:ffff:0:0:0:0:0:0-10,10-20,24,23,22,21,25-ffff");
    make_wc("0:ffff::x");
    make_wc("0:ffff:0:0:0:0:0:aaab-ffff,aaaa-aaaa,0-aaa9");
    make_wc("0:ffff:0:0:0:0:0:ff00/120");
    make_wc("0:ffff:0:0:0:0:0:ffff/120");
    make_wc("::ff00:0/104");
    make_wc("::x");
    make_wc("x::");
    make_wc("x::10.10.10.10");
    make_wc("::");
    make_wc(new_ip("1:2:3:4:5:6:7:8"));
  }

}

###

sub fail_bad_wc_str {
  eval { SILK_IPWILDCARD_CLASS->new(@_) };
  like($@, qr/error.*parsing.*wildcard/, "reject bad str");
}

sub test_bad_strings {

  plan tests => 43;

  fail_bad_wc_str('0.0.0.0/33');
  fail_bad_wc_str('0.0.0.2-0');
  fail_bad_wc_str('0.0.0.256');
  fail_bad_wc_str('0.0.256.0');
  fail_bad_wc_str('0.0.0256.0');
  fail_bad_wc_str('0.256.0.0');
  fail_bad_wc_str('0.0.0.0.0');
  fail_bad_wc_str('0.0.x.0/31');
  fail_bad_wc_str('0.0.x.0:0');
  fail_bad_wc_str('0.0.0,1.0/31');
  fail_bad_wc_str('0.0.0-1.0/31');
  fail_bad_wc_str('0.0.0-1-.0');
  fail_bad_wc_str('0.0.0--1.0');
  fail_bad_wc_str('0.0.0.0 junk');
  fail_bad_wc_str('0.0.-0-1.0');
  fail_bad_wc_str('0.0.-1.0');
  fail_bad_wc_str('0.0.0..0');
  fail_bad_wc_str('.0.0.0.0');
  fail_bad_wc_str('0.0.0.0.');
  fail_bad_wc_str('1-FF::/16');
  fail_bad_wc_str('1,2::/16');
  fail_bad_wc_str('1::2::3');
  fail_bad_wc_str(':1::');
  fail_bad_wc_str(':1:2:3:4:5:6:7:8');
  fail_bad_wc_str('1:2:3:4:5:6:7:8:');
  fail_bad_wc_str('1:2:3:4:5:6:7.8.9:10');
  fail_bad_wc_str('1:2:3:4:5:6:7:8.9.10.11');
  fail_bad_wc_str(':');
  fail_bad_wc_str('1:2:3:4:5:6:7');
  fail_bad_wc_str('1:2:3:4:5:6:7/16');
  fail_bad_wc_str('FFFFF::');
  fail_bad_wc_str('::FFFFF');
  fail_bad_wc_str('1:FFFFF::7:8');
  fail_bad_wc_str('1:AAAA-FFFF0::');
  fail_bad_wc_str('FFFFF-AAAA::');
  fail_bad_wc_str('FFFF-AAAA::');
  fail_bad_wc_str('2-1::');
  fail_bad_wc_str('1:FFFF-0::');
  fail_bad_wc_str('1::FFFF-AAAA');
  fail_bad_wc_str(':::');
  fail_bad_wc_str('1:2:3:$::');
  fail_bad_wc_str('1.2.3.4:ffff::');
  fail_bad_wc_str('x');

}

###

sub t_contains {
  my($wc, $spec) = @_;
  ok($wc->contains($spec), "wc contains $spec");
  my $ip = SILK_IPADDR_CLASS->new($spec);
  ok($wc->contains($ip), "wc contains ip($ip)");
}

sub t_no_contains {
  my($wc, $spec) = @_;
  ok(! $wc->contains($spec), "wc contains $spec");
  my $ip = SILK_IPADDR_CLASS->new($spec);
  ok(! $wc->contains($ip), "wc contains ip($ip)");
}

sub test_containment {

  plan tests => 142;

  my $wild;

  $wild = new_wc("0.0.0.0");
  t_contains   ($wild => "0.0.0.0");
  t_no_contains($wild => "0.0.0.1");

  $wild = new_wc("0.0.0.0/31");
  t_contains   ($wild => "0.0.0.0");
  t_contains   ($wild => "0.0.0.1");
  t_no_contains($wild => "0.0.0.2");

  $wild = new_wc("255.255.255.254-255");
  t_contains   ($wild => "255.255.255.254");
  t_contains   ($wild => "255.255.255.255");
  t_no_contains($wild => "255.255.255.253");

  $wild = new_wc("3,2,1.4.5.6");
  t_contains   ($wild => "1.4.5.6");
  t_contains   ($wild => "2.4.5.6");
  t_contains   ($wild => "3.4.5.6");
  t_no_contains($wild => "4.4.5.6");

  $wild = new_wc("0,255.0,255.0,255.0,255");
  t_contains   ($wild => "0.0.0.0");
  t_contains   ($wild => "0.0.0.255");
  t_contains   ($wild => "0.0.255.0");
  t_contains   ($wild => "0.255.0.0");
  t_contains   ($wild => "255.0.0.0");
  t_contains   ($wild => "255.255.0.0");
  t_contains   ($wild => "255.0.255.0");
  t_contains   ($wild => "255.0.0.255");
  t_contains   ($wild => "0.255.0.255");
  t_contains   ($wild => "0.255.255.0");
  t_contains   ($wild => "0.0.255.255");
  t_contains   ($wild => "0.255.255.255");
  t_contains   ($wild => "255.0.255.255");
  t_contains   ($wild => "255.255.0.255");
  t_contains   ($wild => "255.255.255.0");
  t_contains   ($wild => "255.255.255.255");

  t_no_contains($wild => "255.255.255.254");
  t_no_contains($wild => "255.255.254.255");
  t_no_contains($wild => "255.254.255.255");
  t_no_contains($wild => "254.255.255.255");

  t_contains   ($wild => "0.0.0.0");
  t_contains   ($wild => "0.0.0.255");
  t_contains   ($wild => "0.0.255.0");
  t_contains   ($wild => "0.255.0.0");
  t_contains   ($wild => "255.0.0.0");
  t_contains   ($wild => "255.255.0.0");
  t_contains   ($wild => "255.0.255.0");
  t_contains   ($wild => "255.0.0.255");
  t_contains   ($wild => "0.255.0.255");
  t_contains   ($wild => "0.255.255.0");
  t_contains   ($wild => "0.0.255.255");
  t_contains   ($wild => "0.255.255.255");
  t_contains   ($wild => "255.0.255.255");
  t_contains   ($wild => "255.255.0.255");
  t_contains   ($wild => "255.255.255.0");
  t_contains   ($wild => "255.255.255.255");

  t_no_contains($wild => "255.255.255.254");
  t_no_contains($wild => "255.255.254.255");
  t_no_contains($wild => "255.254.255.255");
  t_no_contains($wild => "254.255.255.255");

  SKIP: {
    skip("ipv6 not enabled", 38) unless SILK_IPV6_ENABLED;

    $wild = new_wc("::");
    t_contains   ($wild => "::");
    t_no_contains($wild => "::1");

    $wild = new_wc("::/127");
    t_contains   ($wild => "::");
    t_contains   ($wild => "::1");
    t_no_contains($wild => "::2");

    $wild = new_wc("0:ffff::0.0.0.0,1");
    t_contains   ($wild => "0:ffff::0.0.0.0");
    t_contains   ($wild => "0:ffff::0.0.0.1");
    t_no_contains($wild => "0:ffff::0.0.0.2");

    $wild = new_wc("0:ffff:0:0:0:0:0.253-254.125-126,255.x");
    t_contains   ($wild => "0:ffff::0.253.125.1");
    t_contains   ($wild => "0:ffff::0.254.125.2");
    t_contains   ($wild => "0:ffff::0.253.126.3");
    t_contains   ($wild => "0:ffff::0.254.126.4");
    t_contains   ($wild => "0:ffff::0.253.255.5");
    t_contains   ($wild => "0:ffff::0.254.255.6");
    t_no_contains($wild => "0:ffff::0.255.255.7");

    $wild = new_wc("0.0.0.0");
    t_contains   ($wild => "::ffff:0:0");
    t_no_contains($wild => "::");

    $wild = new_wc("::ffff:0:0");
    t_contains   ($wild => "0.0.0.0");

    $wild = new_wc("::");
    t_no_contains($wild => "0.0.0.0");
  }
}

###

sub t_ipv4_iter {
  my $wc = new_wc(shift);
  ok(!$wc->is_ipv6, "is ipv4 wildcard");
  my $iter = $wc->iter;
  isa_ok($iter, 'CODE');
  my $i = 0;
  for (my $item = $iter->()) {
    is($item, new_ip($_[$i]), "item match $item");
    ++$i;
  }
  my @wc = $iter->();
}

sub t_ipv6_iter {
  my $wc = new_wc(shift);
  ok($wc->is_ipv6, "is ipv6 wildcard");
  my $iter = $wc->iter;
  isa_ok($iter, 'CODE');
  my $i = 0;
  for (my $item = $iter->()) {
    is($item, new_ip($_[$i]), "item match $item");
    ++$i;
  }
  my @wc = $iter->();
}

sub test_iteration {

  plan tests => 27;

  t_ipv4_iter("0.0.0.0" => "0.0.0.0");
  t_ipv4_iter("0.0.0.0/31" => "0.0.0.0", "0.0.0.1");
  t_ipv4_iter("255.255.255.254-255" =>
              "255.255.255.254", "255.255.255.255");
  t_ipv4_iter("3,2,1.4.5.6" => 
              "1.4.5.6", "2.4.5.6", "3.4.5.6");
  t_ipv4_iter("0,255.0,255.0,255.0,255" =>
              "0.0.0.0",
              "0.0.0.255",
              "0.0.255.0",
              "0.0.255.255",
              "0.255.0.0",
              "0.255.0.255",
              "0.255.255.0",
              "0.255.255.255",
              "255.0.0.0",
              "255.0.0.255",
              "255.0.255.0",
              "255.0.255.255",
              "255.255.0.0",
              "255.255.0.255",
              "255.255.255.0",
              "255.255.255.255");

  SKIP: {
    skip("ipv6 not enabled", 12) unless SILK_IPV6_ENABLED;

    t_ipv6_iter("::" => "::");
    t_ipv6_iter("::/127" => "::0", "::1");
    t_ipv6_iter("0:ffff::0.0.0.0,1" => "0:ffff::0", "0:ffff::1");
    t_ipv6_iter("0:ffff::0.253-254.125-126,255.1" =>
                "0:ffff::0.253.125.1",
                "0:ffff::0.253.126.1",
                "0:ffff::0.253.255.1",
                "0:ffff::0.254.125.1",
                "0:ffff::0.254.126.1",
                "0:ffff::0.254.255.1");
  }

}

###

sub t_isipv4 {
  my $wc = new_wc(shift);
  ok(!$wc->is_ipv6, "is ipv4 wildcard");
}

sub t_isipv6 {
  my $wc = new_wc(shift);
  ok($wc->is_ipv6, "is ipv6 wildcard");
}

sub test_isipv6 {

  plan tests => 9;

  t_isipv4("0.0.0.0");
  t_isipv4("0.0.0.0/31");
  t_isipv4("255.255.255.254-255");
  t_isipv4("3,2,1.4.5.6");
  t_isipv4("0,255.0,255.0,255.0,255");

  SKIP: {
    skip("ipv6 not enabled", 4) unless SILK_IPV6_ENABLED;
    t_isipv6("::");
    t_isipv6("::/127");
    t_isipv6("0:ffff::0.0.0.0,1");
    t_isipv6("0:ffff:0:0:0:0:0.253-254.125-126,255.x");
  }
}

###

sub test_cardinality {

  plan tests => 21;

  my $wc;

  $wc = new_wc("1.2.3.0/24");
  cmp_ok($wc->cardinality, '==', 256, "cardinality");
  $wc = new_wc("1.2.3.4");
  cmp_ok($wc->cardinality, '==', 1, "cardinality");
  $wc = new_wc(16909056);
  cmp_ok($wc->cardinality, '==', 1, "cardinality");
  $wc = new_wc("16909056/24");
  cmp_ok($wc->cardinality, '==', 256, "cardinality");
  $wc = new_wc("1.2.3.x");
  cmp_ok($wc->cardinality, '==', 256, "cardinality");
  $wc = new_wc("1.2.x.4");
  cmp_ok($wc->cardinality, '==', 256, "cardinality");
  $wc = new_wc("1.x.3.4");
  cmp_ok($wc->cardinality, '==', 256, "cardinality");
  $wc = new_wc("x.2.3.4");
  cmp_ok($wc->cardinality, '==', 256, "cardinality");
  $wc = new_wc("x.x.3.4");
  cmp_ok($wc->cardinality, '==', 65536, "cardinality");
  $wc = new_wc("1.2.x.x");
  cmp_ok($wc->cardinality, '==', 65536, "cardinality");
  $wc = new_wc("1.x.x.4");
  cmp_ok($wc->cardinality, '==', 65536, "cardinality");
  $wc = new_wc("x.2.3.x");
  cmp_ok($wc->cardinality, '==', 65536, "cardinality");
  $wc = new_wc("1.2,3.4,5.6,7");
  cmp_ok($wc->cardinality, '==', 8, "cardinality");
  $wc = new_wc("1.2.3.0-255");
  cmp_ok($wc->cardinality, '==', 256, "cardinality");

  SKIP: {
    skip("ipv6 not enabled", 7) unless SILK_IPV6_ENABLED;
    use Math::Int128 qw( uint128 );
    $wc = new_wc("ff80::/16");
    cmp_ok($wc->cardinality, '==',
           uint128("5192296858534827628530496329220096"),
           "cardinality");
    $wc = new_wc("1:2:3:4:5:6:7:x");
    cmp_ok($wc->cardinality, '==', 65536, "cardinality");
    $wc = new_wc("::ffff:0102:0304");
    cmp_ok($wc->cardinality, '==', 1, "cardinality");
    $wc = new_wc("::2-4");
    cmp_ok($wc->cardinality, '==', 3, "cardinality");
    $wc = new_wc("1-2:3-4:5-6:7-8:9-a:b-c:d-e:0-ffff");
    cmp_ok($wc->cardinality, '==', 8388608, "cardinality");
    $wc = new_wc("::");
    cmp_ok($wc->cardinality, '==', 1, "cardinality");
    $wc = new_wc("x:x:x:x:x:x:x:x");
    cmp_ok($wc->cardinality, '==',
           "340282366920938463463374607431768211456",
           "cardinality");
  }
}

###

sub test_all {
  subtest "construction" => \&test_construction;
  subtest "bad strings"  => \&test_bad_strings;
  subtest "containment"  => \&test_containment;
  subtest "cardinality"  => \&test_cardinality;
  subtest "iteration"    => \&test_iteration;
  subtest "isipv6"       => \&test_isipv6;
}

test_all();

###
