use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use silktest;

use Test::More tests => 12;

use Math::Int64  qw( string_to_int64  string_to_uint64  );
use Math::Int128 qw( string_to_int128 string_to_uint128 );
use Math::Int64::die_on_overflow;
use Math::Int128::die_on_overflow;

use Net::Silk qw( :basic );

BEGIN { use_ok( SILK_IPADDR_CLASS ) }

sub make_ip   { new_ok(SILK_IPADDR_CLASS,   \@_ ) }
sub make_ipv4 { new_ok(SILK_IPV4ADDR_CLASS, \@_ ) }
sub make_ipv6 { new_ok(SILK_IPV6ADDR_CLASS, \@_ ) }

sub new_ip   { SILK_IPADDR_CLASS  ->new(@_) }
sub new_ipv4 { SILK_IPV4ADDR_CLASS->new(@_) }
sub new_ipv6 { SILK_IPV6ADDR_CLASS->new(@_) }

###

sub t_ip_ipv4_pair {
  my $spec = shift;
  my $pure = shift;
  my $ip1;
  if ($pure) {
    $ip1  = make_ipv4($spec);
  }
  else {
    $ip1  = make_ip($spec);
  }
  my $ip2  = make_ipv4($spec);
  SKIP: {
    skip("ipv4 construction failed", 2) unless $ip1 && $ip2;
    cmp_ok($ip1, '==', $ip2, "spec($spec) : ip($ip1) == ipv4($ip2)");
    cmp_ok($ip1, 'eq', $ip2, "spec($spec) : ip($ip1) eq ipv4($ip2)");
  }
}

sub t_ip_ipv6_pair {
  my $spec = shift;
  my $pure = shift;
  my $ip1;
  if ($pure) {
    $ip1  = make_ipv6($spec);
  }
  else {
    $ip1  = make_ip($spec);
  }
  my $ip2  = make_ipv6($spec);
  SKIP: {
    skip("ipv6 construction failed", 2) unless $ip1 && $ip2;
    cmp_ok($ip1, '==', $ip2, "spec($spec) : ip($ip1) == ipv6($ip2)");
    cmp_ok($ip1, 'eq', $ip2, "spec($spec) : ip($ip1) eq ipv6($ip2)");
  }
}

sub test_construction {

  plan tests => 288;

  t_ip_ipv4_pair("0.0.0.0");
  t_ip_ipv4_pair("255.255.255.255");
  t_ip_ipv4_pair("10.0.0.0");
  t_ip_ipv4_pair("10.10.10.10");
  t_ip_ipv4_pair("10.11.12.13");
  t_ip_ipv4_pair(" 10.0.0.0");
  t_ip_ipv4_pair("10.0.0.0 ");
  t_ip_ipv4_pair("  10.0.0.0  ");
  t_ip_ipv4_pair("010.000.000.000");
  t_ip_ipv4_pair("4294967295", 1);
  t_ip_ipv4_pair("167772160", 1);
  t_ip_ipv4_pair("168430090", 1);
  t_ip_ipv4_pair("168496141", 1);
  t_ip_ipv4_pair("0xFFFFFFFF", 1);
  SKIP: {
    skip("ipv6 not enabled", 232) unless SILK_IPV6_ENABLED;
    t_ip_ipv6_pair("0:0:0:0:0:0:0:0");
    t_ip_ipv6_pair("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff");
    t_ip_ipv6_pair("10:0:0:0:0:0:0:0");
    t_ip_ipv6_pair("10:10:10:10:10:10:10:10");
    t_ip_ipv6_pair("1010:1010:1010:1010:1010:1010:1010:1010");
    t_ip_ipv6_pair("1011:1213:1415:1617:2021:2223:2425:2627");
    t_ip_ipv6_pair("f0ff:f2f3:f4f5:f6f7:202f:2223:2425:2627");
    t_ip_ipv6_pair("f0ff:faf3:f4f5:f6f7:a0af:aaa3:a4a5:a6a7");
    t_ip_ipv6_pair("     f0ff:faf3:f4f5:f6f7:a0af:aaa3:a4a5:a6a7");
    t_ip_ipv6_pair("f0ff:faf3:f4f5:f6f7:a0af:aaa3:a4a5:a6a7     ");
    t_ip_ipv6_pair("   f0ff:faf3:f4f5:f6f7:a0af:aaa3:a4a5:a6a7  ");
    t_ip_ipv6_pair("::");
    t_ip_ipv6_pair("0::0");
    t_ip_ipv6_pair("0:0::0");
    t_ip_ipv6_pair("0:0:0::0");
    t_ip_ipv6_pair("0:0:0:0::0");
    t_ip_ipv6_pair("0:0:0:0:0::0");
    t_ip_ipv6_pair("0:0:0:0:0:0::0");
    t_ip_ipv6_pair("0:0:0:0:0::0:0");
    t_ip_ipv6_pair("0:0:0:0::0:0:0");
    t_ip_ipv6_pair("0:0:0::0:0:0:0");
    t_ip_ipv6_pair("0:0::0:0:0:0:0");
    t_ip_ipv6_pair("0::0:0:0:0:0:0");
    t_ip_ipv6_pair("0::0:0:0:0:0");
    t_ip_ipv6_pair("0::0:0:0:0");
    t_ip_ipv6_pair("0::0:0:0");
    t_ip_ipv6_pair("0::0:0");
    t_ip_ipv6_pair("::0");
    t_ip_ipv6_pair("::0:0");
    t_ip_ipv6_pair("::0:0:0");
    t_ip_ipv6_pair("::0:0:0:0");
    t_ip_ipv6_pair("::0:0:0:0:0");
    t_ip_ipv6_pair("::0:0:0:0:0:0");
    t_ip_ipv6_pair("0:0:0:0:0:0:0::");
    t_ip_ipv6_pair("0:0:0:0:0:0::0");
    t_ip_ipv6_pair("0:0:0:0:0::");
    t_ip_ipv6_pair("0:0:0:0::");
    t_ip_ipv6_pair("0:0:0::");
    t_ip_ipv6_pair("0:0::");
    t_ip_ipv6_pair("0::");
    t_ip_ipv6_pair("0:0:0:0:0:0:0.0.0.0");
    t_ip_ipv6_pair("0:0:0:0:0::0.0.0.0");
    t_ip_ipv6_pair("0:0:0:0::0.0.0.0");
    t_ip_ipv6_pair("0:0:0::0.0.0.0");
    t_ip_ipv6_pair("0:0::0.0.0.0");
    t_ip_ipv6_pair("0::0.0.0.0");
    t_ip_ipv6_pair("::0.0.0.0");
    t_ip_ipv6_pair("::0:0.0.0.0");
    t_ip_ipv6_pair("::0:0:0.0.0.0");
    t_ip_ipv6_pair("::0:0:0:0.0.0.0");
    t_ip_ipv6_pair("::0:0:0:0:0.0.0.0");
    t_ip_ipv6_pair("::0:0:0:0:0:0.0.0.0");
    t_ip_ipv6_pair("0::0:0:0:0:0.0.0.0");
    t_ip_ipv6_pair("0:0::0:0:0:0.0.0.0");
    t_ip_ipv6_pair("0:0:0::0:0:0.0.0.0");
    t_ip_ipv6_pair("0:0:0:0::0:0.0.0.0");
    t_ip_ipv6_pair("0:0:0:0:0::0.0.0.0");
    t_ip_ipv6_pair("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", 1);
  };
}

###

sub test_bigints {

  plan tests => 24;

  my $i64    = string_to_int64(  "0xFFFFFFFF");
  my $u64    = string_to_uint64( "0xFFFFFFFF");
  my $i128   = string_to_int128( "0xFFFFFFFF");
  my $u128   = string_to_uint128("0xFFFFFFFF");

  my $ip4 = new_ip("255.255.255.255");

  my $ipv4_i64    = make_ipv4($i64);
  my $ipv4_u64    = make_ipv4($u64);
  my $ipv4_i128   = make_ipv4($i128);
  my $ipv4_u128   = make_ipv4($u128);

  cmp_ok($ip4, '==', $ipv4_i64,    "ip == ipv4_int64");
  cmp_ok($ip4, 'eq', $ipv4_i64,    "ip eq ipv4_int64");
  cmp_ok($ip4, '==', $ipv4_u64,    "ip == ipv4_uint64");
  cmp_ok($ip4, 'eq', $ipv4_u64,    "ip eq ipv4_uint64");
  cmp_ok($ip4, '==', $ipv4_i128,   "ip == ipv4_int128");
  cmp_ok($ip4, 'eq', $ipv4_i128,   "ip eq ipv4_int128");
  cmp_ok($ip4, '==', $ipv4_u128,   "ip == ipv4_uint128");
  cmp_ok($ip4, 'eq', $ipv4_u128,   "ip eq ipv4_uint128");

  SKIP: {
    skip("ipv6 not enabled", 12) unless SILK_IPV6_ENABLED;

    my $ip6 = new_ip("::255.255.255.255");

    my $ipv6_i64    = make_ipv6($i64);
    my $ipv6_u64    = make_ipv6($u64);
    my $ipv6_i128   = make_ipv6($i128);
    my $ipv6_u128   = make_ipv6($u128);

    cmp_ok($ip6, '==', $ipv6_i64,    "ip == ipv6_int64");
    cmp_ok($ip6, 'eq', $ipv6_i64,    "ip eq ipv6_int64");
    cmp_ok($ip6, '==', $ipv6_u64,    "ip == ipv6_uint64");
    cmp_ok($ip6, 'eq', $ipv6_u64,    "ip eq ipv6_uint64");
    cmp_ok($ip6, '==', $ipv6_i128,   "ip == ipv6_int128");
    cmp_ok($ip6, 'eq', $ipv6_i128,   "ip eq ipv6_int128");
    cmp_ok($ip6, '==', $ipv6_u128,   "ip == ipv6_uint128");
    cmp_ok($ip6, 'eq', $ipv6_u128,   "ip eq ipv6_uint128");

  };

}

###

sub t_ipv4_str {
  my $str1  = shift;
  my($str2, $label);
  if (@_) {
    $str2  = shift;
    $label = "$str1 eq $str2";
  }
  else {
    $str2  = $str1;
    $label = $str1;
  }
  my $ip = make_ipv4($str1);
  is($ip->str, $str2, "ip->str eq str [$str1] [" . $ip->str . "] vs [$str2]");
  is("$ip", $str2, '"ip" eq str' . " [$str1] [$ip] vs [$str2]");
}

sub t_ip_str {
  my $str1  = shift;
  my($str2, $label);
  if (@_) {
    $str2  = shift;
    $label = "$str1 eq $str2";
  }
  else {
    $str2  = $str1;
    $label = $str1;
  }
  my $ip = make_ip($str1);
  is($ip->str, $str2, "ip->str eq str [$str1] [" . $ip->str . "] vs [$str2]");
  is("$ip", $str2, '"ip" eq str' . " [$str1] [$ip] vs [$str2]");
}

sub t_ipv4_pad_str {
  my $str1 = shift;
  my($str2, $label);
  if (@_) {
    $str2  = shift;
    $label = "$str1 eq $str2";
  }
  else {
    $str2  = $str1;
    $label = $str1;
  }
  my $ip = make_ipv4($str1);
  is($ip->padded, $str2, "ip->padded eq str");
}

sub t_ip_pad_str {
  my $str1 = shift;
  my($str2, $label);
  if (@_) {
    $str2  = shift;
    $label = "$str1 eq $str2";
  }
  else {
    $str2  = $str1;
    $label = $str1;
  }
  my $ip = make_ip($str1);
  is($ip->padded, $str2, "ip->padded eq str");
}

sub test_ip_strings() {

  plan tests => 75;

  t_ipv4_str("0.0.0.0");
  t_ipv4_str("255.255.255.255");
  t_ipv4_str("10.0.0.0");
  t_ipv4_str("10.10.10.10");
  t_ipv4_str("10.11.12.13");

  t_ipv4_pad_str("0.0.0.0"         => "000.000.000.000");
  t_ipv4_pad_str("255.255.255.255" => "255.255.255.255");
  t_ipv4_pad_str("10.0.0.0"        => "010.000.000.000");
  t_ipv4_pad_str("10.10.10.10"     => "010.010.010.010");
  t_ipv4_pad_str("10.11.12.13"     => "010.011.012.013");

  SKIP: {
    skip("ipv6 not enabled", 50) unless SILK_IPV6_ENABLED;
    t_ip_str("0:0:0:0:0:0:0:0", "::");
    t_ip_str("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff");
    t_ip_str("10:0:0:0:0:0:0:0" => "10::");
    t_ip_str("10:10:10:10:10:10:10:10");
    t_ip_str("10:0:0:0:0:0:0:0" => "10::");
    t_ip_str("1010:1010:1010:1010:1010:1010:1010:1010");
    t_ip_str("1011:1213:1415:1617:2021:2223:2425:2627");
    t_ip_str("f0ff:f2f3:f4f5:f6f7:202f:2223:2425:2627");
    t_ip_str("f0ff:faf3:f4f5:f6f7:a0af:aaa3:a4a5:a6a7");
    t_ip_str("1234::5678");

    t_ip_pad_str("0:0:0:0:0:0:0:0" =>
                    "0000:0000:0000:0000:0000:0000:0000:0000");
    t_ip_pad_str("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff");
    t_ip_pad_str("10:0:0:0:0:0:0:0" =>
                    "0010:0000:0000:0000:0000:0000:0000:0000");
    t_ip_pad_str("10:10:10:10:10:10:10:10" =>
                    "0010:0010:0010:0010:0010:0010:0010:0010");
    t_ip_pad_str("1010:1010:1010:1010:1010:1010:1010:1010");
    t_ip_pad_str("1010:1010:1010:1010:1010:1010:1010:1010");
    t_ip_pad_str("1011:1213:1415:1617:2021:2223:2425:2627");
    t_ip_pad_str("f0ff:f2f3:f4f5:f6f7:202f:2223:2425:2627");
    t_ip_pad_str("f0ff:faf3:f4f5:f6f7:a0af:aaa3:a4a5:a6a7");
    t_ip_pad_str("1234::5678" =>
                    "1234:0000:0000:0000:0000:0000:0000:5678");
  }
}

###

sub t_ip_int {
  my($str, $int) = @_;
  $int ||= 0;
  my $ip = make_ipv4($str);
  ok($ip->num == $int, "ip->num == int : $str : $int");
  ok($ip eq $int, "ip eq int : $str : $int");
}

sub t_ip_bigint {
  my($str, $int) = @_;
  $int ||= 0;
  my $bi = string_to_uint128($int);
  my $ip = make_ipv6($str);
  cmp_ok($ip->num, '==', $bi, "ip->num == uint128");
  cmp_ok($ip,      'eq', $bi, "ip eq uint128");
}

sub test_ip_integers {

  plan tests => 213;

  t_ip_int("0.0.0.0"         => 0         );
  t_ip_int("255.255.255.255" => 4294967295);
  t_ip_int("10.0.0.0"        => 167772160 );
  t_ip_int("10.10.10.10"     => 168430090 );
  t_ip_int("10.11.12.13"     => 168496141 );
  t_ip_int(" 10.0.0.0"       => 167772160 );
  t_ip_int("10.0.0.0 "       => 167772160 );
  t_ip_int("  10.0.0.0  ",   => 167772160 );
  t_ip_int("010.000.000.000" => 167772160 );
  t_ip_int("4294967295"      => 4294967295);
  t_ip_int("167772160"       => 167772160 );
  t_ip_int("168430090"       => 168430090 );
  t_ip_int("168496141"       => 168496141 );
  t_ip_int("167772160"       => 167772160 );
  SKIP: {
    skip("ipv6 not enabled", 171) unless SILK_IPV6_ENABLED;
    t_ip_bigint("0:0:0:0:0:0:0:0" => 0);
    t_ip_bigint("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"
                => "0xffffffffffffffffffffffffffffffff");
    t_ip_bigint("10:0:0:0:0:0:0:0"
                => "0x00100000000000000000000000000000");
    t_ip_bigint("10:10:10:10:10:10:10:10"
                => "0x00100010001000100010001000100010");
    t_ip_bigint("1010:1010:1010:1010:1010:1010:1010:1010"
                => "0x10101010101010101010101010101010");
    t_ip_bigint("1011:1213:1415:1617:2021:2223:2425:2627"
                => "0x10111213141516172021222324252627");
    t_ip_bigint("f0ff:f2f3:f4f5:f6f7:202f:2223:2425:2627"
                => "0xf0fff2f3f4f5f6f7202f222324252627");
    t_ip_bigint("f0ff:faf3:f4f5:f6f7:a0af:aaa3:a4a5:a6a7"
                => "0xf0fffaf3f4f5f6f7a0afaaa3a4a5a6a7");
    t_ip_bigint("ffff:ffff:ffff:ffff:ffff:ffff:255.255.255.255"
                => "0xffffffffffffffffffffffffffffffff");
    t_ip_bigint("1010:1010:1010:1010:1010:1010:16.16.16.16"
                => "0x10101010101010101010101010101010");
    t_ip_bigint("1011:1213:1415:1617:2021:2223:36.37.38.39"
                => "0x10111213141516172021222324252627");
    t_ip_bigint("::");
    t_ip_bigint("0::0");
    t_ip_bigint("0:0::0");
    t_ip_bigint("0:0:0::0");
    t_ip_bigint("0:0:0:0::0");
    t_ip_bigint("0:0:0:0:0::0");
    t_ip_bigint("0:0:0:0:0:0::0");
    t_ip_bigint("0:0:0:0:0::0:0");
    t_ip_bigint("0:0:0:0::0:0:0");
    t_ip_bigint("0:0:0::0:0:0:0");
    t_ip_bigint("0:0::0:0:0:0:0");
    t_ip_bigint("0::0:0:0:0:0:0");
    t_ip_bigint("0::0:0:0:0:0");
    t_ip_bigint("0::0:0:0:0");
    t_ip_bigint("0::0:0:0");
    t_ip_bigint("0::0:0");
    t_ip_bigint("::0");
    t_ip_bigint("::0:0");
    t_ip_bigint("::0:0:0");
    t_ip_bigint("::0:0:0:0");
    t_ip_bigint("::0:0:0:0:0");
    t_ip_bigint("::0:0:0:0:0:0");
    t_ip_bigint("0:0:0:0:0:0:0::");
    t_ip_bigint("0:0:0:0:0:0::0");
    t_ip_bigint("0:0:0:0:0::");
    t_ip_bigint("0:0:0:0::");
    t_ip_bigint("0:0:0::");
    t_ip_bigint("0:0::");
    t_ip_bigint("0::");
    t_ip_bigint("0:0:0:0:0:0:0.0.0.0");
    t_ip_bigint("0:0:0:0:0::0.0.0.0");
    t_ip_bigint("0:0:0:0::0.0.0.0");
    t_ip_bigint("0:0:0::0.0.0.0");
    t_ip_bigint("0:0::0.0.0.0");
    t_ip_bigint("0::0.0.0.0");
    t_ip_bigint("::0.0.0.0");
    t_ip_bigint("::0:0.0.0.0");
    t_ip_bigint("::0:0:0.0.0.0");
    t_ip_bigint("::0:0:0:0.0.0.0");
    t_ip_bigint("::0:0:0:0:0.0.0.0");
    t_ip_bigint("::0:0:0:0:0:0.0.0.0");
    t_ip_bigint("0::0:0:0:0:0.0.0.0");
    t_ip_bigint("0:0::0:0:0:0.0.0.0");
    t_ip_bigint("0:0:0::0:0:0.0.0.0");
    t_ip_bigint("0:0:0:0::0:0.0.0.0");
    t_ip_bigint("0:0:0:0:0::0.0.0.0");
  }
}

###

sub test_ipv4_from_int {
  my $int = shift || 0;
  my $ip = SILK_IPV4ADDR_CLASS->from_int($int);
  isa_ok($ip, SILK_IPV4ADDR_CLASS);
  cmp_ok($ip->num, '==', $int, "ipv4 num/int");
  cmp_ok($ip,      'eq', $int, "ipv4 ip/int");
}

sub test_ipv6_from_int {
  my $int = string_to_uint128(shift || 0);
  my $ip = SILK_IPV6ADDR_CLASS->from_int($int);
  isa_ok($ip, SILK_IPV6ADDR_CLASS);
  cmp_ok($ip->num, '==', $int, "ipv6 num/int");
  cmp_ok($ip,      'eq', $int, "ipv6 ip/int");
}

sub fail_ipv4_from_int {
  my $int = shift;
  my $ip;
  eval { $ip = SILK_IPV4ADDR_CLASS->from_int($int) };
  ok($@, "ipv4 int/fail $int");
}

sub fail_ipv6_from_int {
  my $int = shift;
  my $ip;
  eval { $ip = SILK_IPV6ADDR_CLASS->from_int($int) };
  ok($@, "ipv6 int/fail $int");
}

sub test_ip_from_integers {

  plan tests => 33;

  test_ipv4_from_int(0);
  test_ipv4_from_int(4294967295);
  test_ipv4_from_int(167772160);
  test_ipv4_from_int(168430090);
  test_ipv4_from_int(168496141);
  test_ipv4_from_int(167772160);

  fail_ipv4_from_int(-1);
  fail_ipv4_from_int("-1");
  fail_ipv4_from_int(string_to_uint64("0x100000000"));

  SKIP: {
    skip("ipv6 not enabled", 12) unless SILK_IPV6_ENABLED;
    test_ipv6_from_int("0xffffffffffffffffffffffffffffffff");
    test_ipv6_from_int("0x10101010101010101010101010101010");
    test_ipv6_from_int("0x10111213141516172021222324252627");

    fail_ipv6_from_int(-1);
    fail_ipv6_from_int("-1");
    fail_ipv6_from_int("0x100000000000000000000000000000000");
  }
}

###

my $pat = qr/
  (error.*parsing.*(string | IP)) |
  (IPv6.*not\s+supported)         |
  (invalid\s*IP(v\d)?\s*(numeric|string\s*)?address)
  /ix;

sub fail_bad_str {
  my $str = shift;
  my $ip;
  eval { $ip = SILK_IPADDR_CLASS->new($str) };
  like($@, $pat, "ip str/fail [$str]");
}

sub fail_bad_ipv4_str {
  my $str = shift;
  my $ip;
  eval { $ip = SILK_IPV4ADDR_CLASS->new($str) };
  like($@, $pat, "ipv4 str/fail [$str]");
}

sub fail_bad_ipv6_str {
  my $str = shift;
  my $ip;
  eval { $ip = SILK_IPV6ADDR_CLASS->new($str) };
  like($@, $pat, "ipv6 str/fail [$str]");
}

sub test_ip_bad_strings {

  plan tests => 52;

  fail_bad_str("010.000.000.000x");
  fail_bad_str("010.000.000.000a");
  fail_bad_str("010.000.000.000|");
  fail_bad_str("10.0.0.0       .");
  fail_bad_str("      167772160|");
  fail_bad_str("    10.10.10.10.10  ");
  fail_bad_str("");
  fail_bad_str("  ");
  fail_bad_str("     -167772160");
  fail_bad_str("     -167772160|");
  fail_bad_str("      167772160.");
  fail_bad_str(" 256.256.256.256");
  fail_bad_str("  10.");
  fail_bad_str("  10.x.x.x  ");
  fail_bad_str("  .10.10.10.10  ");
  fail_bad_str("  10..10.10.10  ");
  fail_bad_str("  10.10..10.10  ");
  fail_bad_str("  10.10.10..10  ");
  fail_bad_str("  10.10.10.10.  ");
  fail_bad_str("10.0.0.98752938745983475983475039248759");
  fail_bad_str("10.0|0.0");
  fail_bad_str(" 10.  0.  0.  0");
  fail_bad_str("10 .   0.  0.  0");

  my $failer = SILK_IPV6_ENABLED ? \&fail_bad_ipv6_str : \&fail_bad_str;

  $failer->("       10.0.0.0:80");
  $failer->("  10.10:10.10   ");
  $failer->(" -10:0:0:0:0:0:0:0");
  $failer->(" 10000:0:0:0:0:0:0:0");
  $failer->(" 0:0:0:0:0:0:0:10000");
  $failer->("  10:");
  $failer->("0:0:0:0:0:0:0");
  $failer->("  10:10.10:10::");
  $failer->("  :10:10:10:10::");
  $failer->("  ::10:10:10:10:STUFF");
  $failer->("  ::10:10:10:10:");
  $failer->("  10:10:10:::10");
  $failer->("  10::10:10::10");
  $failer->("  10:10::10::10");
  $failer->("  10::10::10:10");
  $failer->("  10:x:x:x:x:x:x:x  ");
  $failer->("f0ff:faf3:f4f5:f6f7:a0af:aaa3:a4a5:a6a7:ffff");
  $failer->("11:12:13:14:15:16:17:");
  $failer->("9875293874598347598347503924875998758274950699387273273849");
  $failer->("10:0|0:0:0:0:0:0");
  $failer->(" 10:  0:  0:  0: 10: 10: 10: 10");
  $failer->("10 :10:10:10:10:10:10:10");
  $failer->(":10:10:10:10:10:10:10:10");
  $failer->("0:0:0:0:0:0:0:0:0.0.0.0");
  $failer->("0:0:0:0:0:0:0:0.0.0.0");
  $failer->("::0.0.0.0:0");
  $failer->("0::0.0.0.0:0");
  $failer->("0::0.0.0.0.0");

  fail_bad_ipv4_str("::");

}

###

sub ipv4_order_cmp {
  my($cmp, $v1, $v2) = @_;
  cmp_ok(new_ipv4($v1), $cmp, new_ipv4($v2), "ip4 $cmp ip4");
}

sub ipv6_order_cmp {
  my($cmp, $v1, $v2) = @_;
  cmp_ok(new_ipv6($v1), $cmp, new_ipv6($v2), "ip6 $cmp ip6");
}

sub test_ip_ordering {

  plan tests => 20;

  ipv4_order_cmp('==' => 0, 0);
  ipv4_order_cmp('<'  => 0, 256);
  ipv4_order_cmp('>'  => 256, 0);
  ipv4_order_cmp('!=' => 256, 0);
  ipv4_order_cmp('==' => 0xffffffff, 0xffffffff);
  ipv4_order_cmp('eq' => 0, 0);
  ipv4_order_cmp('lt' => 0, 256);
  ipv4_order_cmp('gt' => 256, 0);
  ipv4_order_cmp('ne' => 256, 0);
  ipv4_order_cmp('eq' => 0xffffffff, 0xffffffff);
  SKIP: {
    skip("ipv6 not enabled", 10) unless SILK_IPV6_ENABLED;

    ipv6_order_cmp('<'  => 0xffffffff, "ffff::");
    ipv6_order_cmp('!=' => 0xffffffff, "255.255.255.255");
    ipv6_order_cmp('>'  => "255.255.255.255", "::255.255.255.255");
    ipv6_order_cmp('==' => "0.0.0.0", "::ffff:0.0.0.0");
    ipv6_order_cmp('<'  => "0.0.0.0", "::ffff:0.0.0.1");
    ipv6_order_cmp('lt' => 0xffffffff, "ffff::");
    ipv6_order_cmp('ne' => 0xffffffff, "255.255.255.255");
    ipv6_order_cmp('gt' => "255.255.255.255", "::255.255.255.255");
    ipv6_order_cmp('eq' => "0.0.0.0", "::ffff:0.0.0.0");
    ipv6_order_cmp('lt' => "0.0.0.0", "::ffff:0.0.0.1");

  }
}

###

sub test_ipv6_addr {

  plan tests => 8;

  SKIP: {
    skip("ipv6 not enabled", 4) unless SILK_IPV6_ENABLED;
    ok(make_ip("::")->is_ipv6, "ip->is_ipv6");
    ok(make_ip("::ffff:0.0.0.1")->is_ipv6, "ip->is_ipv6");
  }
  ok(! make_ip("0.0.0.0")->is_ipv6, "! ip->is_ipv6");
  ok(! make_ip("0.0.0.1")->is_ipv6, "! ip->is_ipv6");
}

###

sub test_ip_convert {

  plan tests => 16;

  my $ip1 = new_ip("0.0.0.0");
  cmp_ok($ip1, '==', $ip1, "ip4 == ip4");
  cmp_ok($ip1, 'eq', $ip1, "ip4 eq ip4");
  cmp_ok($ip1, 'eq', new_ipv4($ip1), "ip4 eq new4(ip4)");
  cmp_ok($ip1, 'eq', $ip1->as_ipv4, "ip4 eq ip4->as_ipv4");
  SKIP: {
    skip("ipv6 not enabled", 10) unless SILK_IPV6_ENABLED;
    my $ip2 = new_ip("::");
    my $ip3 = new_ip("::ffff:0.0.0.0");
    isa_ok($ip1->as_ipv6, SILK_IPV6ADDR_CLASS);
    isa_ok($ip3->as_ipv4, SILK_IPV4ADDR_CLASS);
    cmp_ok($ip2, 'eq', new_ipv6($ip2), "ip6 eq new6(ip6)");
    cmp_ok($ip3, 'eq', new_ipv6($ip3), "ip6 eq new6(ip6)");
    cmp_ok($ip3, 'eq', new_ipv6($ip1), "ip6 eq new6(ip4)");
    cmp_ok($ip3, 'eq', $ip1->as_ipv6,  "ip6 eq ip4->as_ipv6");
    cmp_ok($ip1, 'eq', new_ipv4($ip3), "ip4 eq new4(ip6)");
    cmp_ok($ip1, 'eq', $ip3->as_ipv4,  "ip4 eq ip6->as_ipv4");
    eval { new_ipv4($ip2) };
    ok($@, "new4(ipv6): out of range");
    cmp_ok(0, '==', $ip2->as_ipv4 || 0, "undef == ip6->as_ipv4");
  }
  SKIP: {
    skip("ipv6 enabled", 2) if SILK_IPV6_ENABLED;
    eval { $ip1->as_ipv6 };
    ok($@, "ipv4->as_ipv6: ipv6 not enabled");
    eval { SILK_IPV6ADDR_CLASS->new($ip1) };
    ok($@, "new6(ipv4): ipv6 not enabled");
  }
}

###

sub test_ip_octets {

  plan tests => 2;

  my $ip = new_ip("10.11.12.13");
  is_deeply([$ip->octets], [10, 11, 12, 13], "ip4 octets");
  SKIP: {
    skip("ipv6 not enabled", 1) unless SILK_IPV6_ENABLED;
    $ip = new_ip("2001:db8:10:11::12:13");
    is_deeply([$ip->octets],
              [0x20, 0x01, 0x0d, 0xb8,
               0x00, 0x10, 0x00, 0x11,
               0x00, 0x00, 0x00, 0x00,
               0x00, 0x12, 0x00, 0x13], "ip6 octets");
  }
}

###

sub test_ip_masking {

  plan tests => 44;

  my($ip1, $ip2, $msk, $pfx);

  $msk = new_ip("0.0.0.0");

  $ip1 = new_ip("10.11.12.13");
  is($ip1, $ip1->mask_prefix(32), "$ip1 eq $ip1->mask_prefix(32)");
  is($msk, $ip1->mask_prefix(0),  "$msk eq $ip1->mask_prefix(0)");

  eval { $ip1->mask_prefix(33) };
  ok($@, "ipv4 mask prefix out of range (33)");

  is($msk, $ip1->mask($msk), "$msk eq $ip1->mask($msk)");
  is($msk, $msk->mask($ip1), "$msk eq $msk->mask($ip1)");
  is($msk, $msk->mask($msk), "$msk eq $msk->mask($msk)");
  
  $pfx = 24;
  $msk = new_ip("255.255.255.0");
  $ip2 = new_ip("10.11.12.0");

  is($ip2, $ip1->mask($msk),        "$ip2 eq $ip1->mask($msk)");
  is($ip2, $ip1->mask_prefix($pfx), "$ip2 eq $ip1->mask_prefix($pfx)");
  is($ip2, $ip2->mask($msk),        "$ip2 eq $ip2->mask($msk)");
  is($ip2, $ip2->mask_prefix($pfx), "$ip2 eq $ip2->mask_prefix($pfx)");

  $pfx = 16;
  $msk = new_ip("255.255.0.0");
  $ip2 = new_ip("10.11.0.0");

  is($ip2, $ip1->mask($msk),        "$ip2 eq $ip1->mask($msk)");
  is($ip2, $ip1->mask_prefix($pfx), "$ip2 eq $ip1->mask_prefix($pfx)");
  is($ip2, $ip2->mask($msk),        "$ip2 eq $ip2->mask($msk)");
  is($ip2, $ip2->mask_prefix($pfx), "$ip2 eq $ip2->mask_prefix($pfx)");

  $pfx = 8;
  $msk = new_ip("255.0.0.0");
  $ip2 = new_ip("10.0.0.0");

  is($ip2, $ip1->mask($msk),        "$ip2 eq $ip1->mask($msk)");
  is($ip2, $ip1->mask_prefix($pfx), "$ip2 eq $ip1->mask_prefix($pfx)");
  is($ip2, $ip2->mask($msk),        "$ip2 eq $ip2->mask($msk)");
  is($ip2, $ip2->mask_prefix($pfx), "$ip2 eq $ip2->mask_prefix($pfx)");

  SKIP: {
    skip("ipv6 not enabled", 26) unless SILK_IPV6_ENABLED;

    $msk = new_ip("::");

    $pfx = 128;
    $ip1 = new_ip("2001:db8:10:11::12:13");
    is($ip1, $ip1->mask_prefix($pfx), "ident mask_prefix($pfx)");
    is($msk, $ip1->mask_prefix(0), "zed mask_prefix(0)");

    eval { $ip1->mask_prefix(129) };
    ok($@, "ipv6 mask prefix out of range (129)");

    is($msk, $ip1->mask($msk), "zed eq ip6->mask(zed)");
    is($msk, $msk->mask($ip1), "zed eq zed->mask(ip6)");
    is($msk, $msk->mask($msk), "zed eq zed->mask(zed)");

    $pfx = 112;
    $msk = new_ip("ffff:ffff:ffff:ffff:ffff:ffff:ffff:0");
    $ip2 = new_ip("2001:db8:10:11::12:0");
    is($ip2, $ip1->mask($msk), "ip6.2 eq ip6.1->mask(msk)");
    is($ip2, $ip1->mask_prefix($pfx), "ip6.2 eq ip6.1->mask_prefix($pfx)");
    is($ip2, $ip2->mask($msk), "ip6.1 eq ip6.1->mask(msk)");
    is($ip2, $ip2->mask_prefix($pfx), "ip6.1 eq ip6.1->mask_prefix($pfx)");

    $pfx = 64;
    $msk = new_ip("ffff:ffff:ffff:ffff::");
    $ip2 = new_ip("2001:db8:10:11::");
    is($ip2, $ip1->mask($msk), "ip6.2 eq ip6.1->mask(msk)");
    is($ip2, $ip1->mask_prefix($pfx), "ip6.2 eq ip6.1->mask_prefix($pfx)");
    is($ip2, $ip2->mask($msk), "ip6.2 eq ip6.2->mask(msk)");
    is($ip2, $ip2->mask_prefix($pfx), "ip6.2 eq ip6.2->mask_prefix($pfx)");

    # Mixed IPv4 and IPv6

    $pfx = 128;
    $msk = new_ip("::FFFF:0.0.0.0");
    $ip1 = new_ip("::FFFF:10.11.12.13");
    is($ip1->mask_prefix($pfx), $ip1, "ip eq ip->mask_prefix($pfx)");
    is($ip1->mask($msk),        $msk, "msk eq ip->mask(msk)");
    is($msk->mask($ip1),        $msk, "msk eq msk->mask(ip)");
    is($msk->mask($msk),        $msk, "msk eq msk->mask(msk)");

    $pfx = 120;
    $msk = new_ip("255.255.255.0");
    $ip2 = new_ip("::FFFF:10.11.12.0");
    is($ip1->mask($msk),        $ip2, "ip.2 eq ip.1->mask(msk)");
    is($ip1->mask_prefix($pfx), $ip2, "ip.2 eq ip.1->mask_prefix($pfx)");
    is($ip2->mask($msk),        $ip2, "ip.1 eq ip.1->mask(msk)");
    is($ip2->mask_prefix($pfx), $ip2, "ip.1 eq ip.1->mask_prefix($pfx)");

    $pfx = 112;
    $msk = new_ip("255.255.0.0");
    $ip2 = new_ip("::FFFF:10.11.0.0");
    is($ip1->mask($msk),        $ip2, "ip.2 eq ip.1->mask(msk)");
    is($ip1->mask_prefix($pfx), $ip2, "ip.2 eq ip.1->mask_prefix($pfx)");
    is($ip2->mask($msk),        $ip2, "ip.1 eq ip.1->mask(msk)");
    is($ip2->mask_prefix($pfx), $ip2, "ip.1 eq ip.1->mask_prefix($pfx)");
  }
}

###

sub test_all {

  subtest "construction"  => \&test_construction;
  subtest "bigints     "  => \&test_bigints;
  subtest "strings"       => \&test_ip_strings;
  subtest "integers"      => \&test_ip_integers;
  subtest "from integers" => \&test_ip_from_integers;
  subtest "bad strings"   => \&test_ip_bad_strings;
  subtest "ordering "     => \&test_ip_ordering;
  subtest "ipv6 new/fail" => \&test_ipv6_addr;
  subtest "conversion"    => \&test_ip_convert;
  subtest "octets"        => \&test_ip_octets;
  subtest "masking"       => \&test_ip_masking;

}

test_all();

###
