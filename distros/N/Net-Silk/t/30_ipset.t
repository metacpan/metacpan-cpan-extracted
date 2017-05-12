use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use silktest;

use Test::More tests => 18;

use Net::Silk qw( :basic );

BEGIN { use_ok( SILK_IPSET_CLASS ) }

sub make_set { new_ok(SILK_IPSET_CLASS, \@_ ) }

sub new_set {      SILK_IPSET_CLASS->new(@_) }
sub new_ip  {     SILK_IPADDR_CLASS->new(@_) }
sub new_wc  { SILK_IPWILDCARD_CLASS->new(@_) }

###

sub t_mk_set {
  my $s = make_set(@_);
  #cmp_ok($s->cardinality, '==', scalar @_, "set size " . scalar @_);
  $s;
}

sub t_mk_ip_set { t_mk_set(map { new_ip($_) } @_ ) }

sub test_construction {

  plan tests => 34;

  my($s1, $s2, $fn);
  #
  $s1 = t_mk_set();
  $fn = t_tmp_filename();
  eval { $s1->save($fn) };
  ok(!$@, "save rwset file");
  ok(-f $fn, "rwset file exists");
  $s2 = SILK_IPSET_CLASS->load($fn);
  ok(ref $s2, "load rwset file");
  isa_ok($s2, SILK_IPSET_CLASS);
  unlink $fn;
  #
  $s1 = t_mk_set   ("1.2.3.4");
  cmp_ok($s1->cardinality, '==', 1, "set size 1");
  $s1 = t_mk_set   ("1.2.3.4", "5.6.7.8");
  cmp_ok($s1->cardinality, '==', 2, "set size 2");
  $s1 = t_mk_ip_set("1.2.3.4");
  $s1 = t_mk_ip_set("1.2.3.4", "5.6.7.8");
  cmp_ok($s1->cardinality, '==', 2, "set size 2");
  $s1 = t_mk_ip_set("1.2.3.4", new_ip("5.6.7.8"));
  cmp_ok($s1->cardinality, '==', 2, "set size 2");
  $s1 = t_mk_set(["1.2.3.4", "5.6.7.8"]);
  cmp_ok($s1->cardinality, '==', 2, "set size 2");
  $s1 = t_mk_set("1.1.1.1-1.1.1.5");
  cmp_ok($s1->cardinality, '==', 5, "set size 5");
  $s1 = t_mk_set("1.2.3.4/27");
  cmp_ok($s1->cardinality, '==', 32, "set size 32");
  $s1 = t_mk_set(SILK_IPWILDCARD_CLASS->new("1.2.3.4-10"));
  cmp_ok($s1->cardinality, '==', 7, "set size 7");
  $s1 = t_mk_set($s1);
  cmp_ok($s1->cardinality, '==', 7, "set size 7");

  SKIP: {
    skip("ipv6 not enabled", 10) unless SILK_IPV6_ENABLED;
    $s1 = t_mk_set   ("2001:db8:1:2::3:4");
    cmp_ok($s1->cardinality, '==', 1, "set size 1");
    $s1 = t_mk_set   ("2001:db8:1:2::3:4", "2001:db8:5:6::7:8");
    cmp_ok($s1->cardinality, '==', 2, "set size 2");
    $s1 = t_mk_ip_set("2001:db8:1:2::3:4");
    cmp_ok($s1->cardinality, '==', 1, "set size 1");
    $s1 = t_mk_ip_set("2001:db8:1:2::3:4", "2001:db8:5:6::7:8");
    cmp_ok($s1->cardinality, '==', 2, "set size 2");
    $s1 = t_mk_ip_set("2001:db8:1:2::3:4", new_ip("2001:db8:5:6::7:8"));
    cmp_ok($s1->cardinality, '==', 2, "set size 2");
  }
}

###

sub test_supports_ipv6 {

  plan tests => 3;

  cmp_ok(SILK_IPSET_CLASS->supports_ipv6, '==',
         SILK_IPV6_ENABLED, 'supports ipv6');
  cmp_ok(t_mk_set()->supports_ipv6, '==',
         SILK_IPV6_ENABLED, 'supports ipv6');
}

###

sub t_contains {
  my($s, $v) = @_;
  ok($s->contains($v), "contains $v");
}

sub t_contains_ip {
  my($s, $v) = @_;
  t_contains($s, new_ip($v));
}

sub t_no_contains {
  my($s, $v) = @_;
  ok(!$s->contains($v), "missing $v");
}

sub t_no_contains_ip {
  my($s, $v) = @_;
  t_no_contains($s, new_ip($v));
}

sub test_add_contain {

  plan tests => 20;

  my $s = new_set;

  $s->add("1.2.3.4");
  t_contains      ($s, "1.2.3.4");
  t_no_contains   ($s, "0.0.0.0");
  t_contains_ip   ($s, "1.2.3.4");
  t_no_contains_ip($s, "0.0.0.0");

  $s->add("5.6.7.8");
  t_contains      ($s, "1.2.3.4");
  t_contains      ($s, "5.6.7.8");
  t_no_contains   ($s, "0.0.0.0");
  t_contains_ip   ($s, "1.2.3.4");
  t_contains_ip   ($s, "5.6.7.8");
  t_no_contains_ip($s, "0.0.0.0");

  SKIP: {
    skip("ipv6 not enabled", 10) unless SILK_IPV6_ENABLED;
    $s = new_set;

    $s->add("2001:db8:1:2::3:4");
    t_contains      ($s, "2001:db8:1:2::3:4");
    t_no_contains   ($s, "2001:db8:0:0::0:0");
    t_contains_ip   ($s, "2001:db8:1:2::3:4");
    t_no_contains_ip($s, "2001:db8:0:0::0:0");

    $s->add("2001:db8:5:6::7:8");
    t_contains      ($s, "2001:db8:1:2::3:4");
    t_contains      ($s, "2001:db8:5:6::7:8");
    t_no_contains   ($s, "2001:db8:0:0::0:0");
    t_contains_ip   ($s, "2001:db8:1:2::3:4");
    t_contains_ip   ($s, "2001:db8:5:6::7:8");
    t_no_contains_ip($s, "2001:db8:0:0::0:0");
  }
}

###

sub test_promotion {

  plan tests => 12;

  SKIP: {
    skip("ipv6 not enabled", 12) unless SILK_IPV6_ENABLED;
    my $s = new_set;
    $s->add("1.2.3.4");
    $s->add("2001:db8:1:2::3:4");
    t_contains      ($s, "1.2.3.4");
    t_no_contains   ($s, "0.0.0.0");
    t_contains_ip   ($s, "1.2.3.4");
    t_no_contains_ip($s, "0.0.0.0");
    t_contains      ($s, "2001:db8:1:2::3:4");
    t_no_contains   ($s, "2001:db8:0:0::0:0");
    t_contains_ip   ($s, "2001:db8:1:2::3:4");
    t_no_contains_ip($s, "2001:db8:0:0::0:0");
    t_contains      ($s, "::ffff:1.2.3.4" );
    t_no_contains   ($s, "::ffff:0.0.0.0");
    t_contains_ip   ($s, "::ffff:1.2.3.4");
    t_no_contains_ip($s, "::ffff:0.0.0.0");
  }
}

###

sub test_copy {

  plan tests => 20;

  my $s1 = new_set();
  my $s2 = $s1;
  my $s3 = $s1->copy;
  cmp_ok($s1, '==', $s2, "s1 == s2");
  cmp_ok($s2, '==', $s3, "s2 == s3");
  cmp_ok($s3, '==', $s1, "s3 == s1");
  is  ("$s2", "$s1", "s1 is s2");
  isnt("$s3", "$s1", "s1 is not s3");

  $s1->add("1.2.3.4");
  $s1->add("5.6.7.8");
  $s3 = $s1->copy;
  cmp_ok($s1, '==', $s2, "s1 == s2");
  cmp_ok($s2, '==', $s3, "s2 == s3");
  cmp_ok($s3, '==', $s1, "s3 == s1");
  cmp_ok("$s1", 'eq', "$s2", "s1 is s2");
  cmp_ok("$s1", 'ne', "$s3", "s1 is not s3");

  SKIP: {
    skip("ipv6 not enabled", 10) unless SILK_IPV6_ENABLED;
      $s1 = new_set();
      # force set to be IPv6
      $s1->add("::");
      $s1->remove("::");
      $s2 = $s1;
      $s3 = $s1->copy;
      cmp_ok($s1, '==', $s2, "s1 == s2");
      cmp_ok($s2, '==', $s3, "s2 == s3");
      cmp_ok($s3, '==', $s1, "s3 == s1");
      cmp_ok("$s1", 'eq', "$s2", "s1 is s2");
      cmp_ok("$s1", 'ne', "$s3", "s1 is not s3");
      
      $s1->add("2001:db8:1:2::3:4");
      $s1->add("2001:db8:5:6::7:8");
      $s3 = $s1->copy;
      cmp_ok($s1, '==', $s2, "s1 == s2");
      cmp_ok($s2, '==', $s3, "s2 == s3");
      cmp_ok($s3, '==', $s1, "s3 == s1");
      cmp_ok("$s1", 'eq', "$s2", "s1 is s2");
      cmp_ok("$s1", 'ne', "$s3", "s1 is not s3");
  }
}

###

sub test_remove {

  plan tests => 12;

  my $s = new_set();
  $s->add("1.2.3.4");
  $s->add("5.6.7.8");
  t_contains($s, "1.2.3.4");
  t_contains($s, "5.6.7.8");
  $s->remove("1.2.3.4");
  t_no_contains($s, "1.2.3.4");
  t_contains   ($s, "5.6.7.8");
  $s->remove("5.6.7.8");
  t_no_contains($s, "1.2.3.4");
  t_no_contains($s, "5.6.7.8");

  SKIP: {
    skip("ipv6 not enabled", 6) unless SILK_IPV6_ENABLED;
    $s = new_set();
    $s->add("2001:db8:1:2::3:4");
    $s->add("2001:db8:5:6::7:8");
    t_contains($s, "2001:db8:1:2::3:4");
    t_contains($s, "2001:db8:5:6::7:8");
    $s->remove("2001:db8:1:2::3:4");
    t_no_contains($s, "2001:db8:1:2::3:4");
    t_contains   ($s, "2001:db8:5:6::7:8");
    $s->remove("2001:db8:5:6::7:8");
    t_no_contains($s, "2001:db8:1:2::3:4");
    t_no_contains($s, "2001:db8:5:6::7:8");
  }
}

###

sub test_clear {

  plan tests => 8;

  my $s = new_set();
  $s->add("1.2.3.4");
  $s->add("5.6.7.8");
  t_contains($s, "1.2.3.4");
  t_contains($s, "5.6.7.8");
  $s->clear;
  t_no_contains($s, "1.2.3.4");
  t_no_contains($s, "5.6.7.8");

  SKIP: {
    skip("ipv6 not enabled", 4) unless SILK_IPV6_ENABLED;
    $s = new_set();
    $s->add("2001:db8:1:2::3:4");
    $s->add("2001:db8:5:6::7:8");
    t_contains($s, "2001:db8:1:2::3:4");
    t_contains($s, "2001:db8:5:6::7:8");
    $s->clear;
    t_no_contains($s, "2001:db8:1:2::3:4");
    t_no_contains($s, "2001:db8:5:6::7:8");
  }
}

###

sub test_cardinality {

  #plan tests => 12;
  plan tests => 6;

  my $s = new_set();
  cmp_ok($s->cardinality, '==', 0, "s size 0");
  #cmp_ok(int($s), '==', 0, "int(s) is 0");
  $s->add("1.2.3.4");
  $s->add("5.6.7.8");
  cmp_ok($s->cardinality, '==', 2, "s size 2");
  #cmp_ok(int($s), '==', 2, "int(s) is 2");
  $s->remove("1.2.3.4");
  cmp_ok($s->cardinality, '==', 1, "s size 1");
  #cmp_ok(int($s), '==', 1, "int(s) is 1");
  SKIP: {
    skip("ipv6 not enabled", 3) unless SILK_IPV6_ENABLED;
    $s = new_set();
    $s->add("::");
    $s->remove("::");
    cmp_ok($s->cardinality, '==', 0, "s size 0");
    #cmp_ok(int($s), '==', 0, "int(s) is 0");
    $s->add("2001:db8:1:2::3:4");
    $s->add("2001:db8:5:6::7:8");
    cmp_ok($s->cardinality, '==', 2, "s size 2");
    #cmp_ok(int($s), '==', 2, "int(s) is 2");
    $s->remove("2001:db8:1:2::3:4");
    cmp_ok($s->cardinality, '==', 1, "s size 1");
    #cmp_ok(int($s), '==', 1, "int(s) is 1");
  }
}

###

sub test_add_types {

  plan tests => 16;

  my $r1 = "1.1.1.0/27";
  my $r2 = SILK_CIDR_CLASS->new($r1);
  my $r3 = "1.1.1.0-1.1.1.31";
  my $r4 = SILK_RANGE_CLASS->new($r3);

  my $s;

  $s = make_set($r1);
  cmp_ok($s->cardinality, '==', 32, "cidr1 cardinality");
  $s = make_set($r2);
  cmp_ok($s->cardinality, '==', 32, "cidr2 cardinality");
  $s = make_set($r3);
  cmp_ok($s->cardinality, '==', 32, "range1 cardinality");
  $s = make_set($r4);
  cmp_ok($s->cardinality, '==', 32, "range2 cardinality");

  $s = new_set;
  $s->add($r1);
  cmp_ok($s->cardinality, '==', 32, "cidr1 add cardinality");
  $s = new_set;
  $s->add_cidr($r1);
  cmp_ok($s->cardinality, '==', 32, "cidr1 add_cidr cardinality");

  $s = new_set;
  $s->add($r2);
  cmp_ok($s->cardinality, '==', 32, "cidr2 add cardinality");
  $s = new_set;
  $s->add_cidr($r2);
  cmp_ok($s->cardinality, '==', 32, "cidr2 add_cidr cardinality");

  $s = new_set;
  $s->add($r3);
  cmp_ok($s->cardinality, '==', 32, "range1 add cardinality");
  $s = new_set;
  $s->add_range($r3);
  cmp_ok($s->cardinality, '==', 32, "range1 add range cardinality");

  $s = new_set;
  $s->add($r4);
  cmp_ok($s->cardinality, '==', 32, "range2 add cardinality");
  $s = new_set;
  $s->add_range($r4);
  cmp_ok($s->cardinality, '==', 32, "range2 add range cardinality");

}



###

sub test_supersub {

  plan tests => 40;

  my $s1 = new_set();
  my $s2 = new_set();

  ok($s1->is_subset  ($s2), "s1 subset of s2");
  ok($s2->is_subset  ($s1), "s2 subset of s1");
  ok($s1->is_superset($s2), "s1 superset of s2");
  ok($s2->is_superset($s1), "s2 superset of s1");
  cmp_ok($s1, '<=', $s2, "s1 <= s2");
  cmp_ok($s2, '<=', $s1, "s2 <= s1");
  cmp_ok($s1, '>=', $s2, "s1 >= s2");
  cmp_ok($s2, '>=', $s1, "s2 >= s1");

  $s1->add("1.2.3.4");
  $s1->add("5.6.7.8");
  $s2->add("5.6.7.8");

  #print STDERR "S1 $s1 : ", join(', ', keys %$s1), "\n";
  #print STDERR "S2 $s2 : ", join(', ', keys %$s2), "\n";

  ok(! $s1->is_subset  ($s2), "s1 not subset of s2");
  ok(  $s2->is_subset  ($s1), "s2 subset of s1");
  ok(  $s1->is_superset($s2), "s1 superset of s2");
  ok(! $s2->is_superset($s1), "s2 not superset of s1");
  ok(!  ($s1   <=   $s2), "!(s1 <= s2)");
  cmp_ok($s2, '<=', $s1,  "s2 <= s1");
  cmp_ok($s1, '>=', $s2,  "s1 >= s2");
  ok(!  ($s2   >=   $s1), "!(s2 >= s1)");

  ok( $s2->is_subset("1.2.3.4", "5.6.7.8"),
      "s2 is subset of items");
  ok(!$s2->is_subset("1.2.3.4"),
      "s2 is not subset of item");
  ok( $s1->is_superset("1.2.3.4"),
      "s1 is superset of item");
  ok(!$s1->is_superset("1.2.3.4", "0.0.0.0"),
      "s1 is not superset of items");

  SKIP: {
    skip("ipv6 not enabled", 20) unless SILK_IPV6_ENABLED;
    $s1 = new_set();
    $s2 = new_set();
    $s1->add("::");
    $s1->remove("::");
    $s2->add("::");
    $s2->remove("::");

    ok($s1->is_subset  ($s2), "s1 subset of s2");
    ok($s2->is_subset  ($s1), "s2 subset of s1");
    ok($s1->is_superset($s2), "s1 superset of s2");
    ok($s2->is_superset($s1), "s2 superset of s1");
    cmp_ok($s1, '<=', $s2, "s1 <= s2");
    cmp_ok($s2, '<=', $s1, "s2 <= s1");
    cmp_ok($s1, '>=', $s2, "s1 >= s2");
    cmp_ok($s2, '>=', $s1, "s2 >= s1");

    $s1->add("2001:db8:1:2::3:4");
    $s1->add("2001:db8:5:6::7:8");
    $s2->add("2001:db8:5:6::7:8");

    ok(! $s1->is_subset  ($s2), "s1 not subset of s2");
    ok(  $s2->is_subset  ($s1), "s2 subset of s1");
    ok(  $s1->is_superset($s2), "s1 superset of s2");
    ok(! $s2->is_superset($s1), "s2 not superset of s1");
    ok(!  ($s1   <=   $s2), "!(s1 <= s2)");
    cmp_ok($s2, '<=', $s1,  "s2 <= s1");
    cmp_ok($s1, '>=', $s2,  "s1 >= s2");
    ok(!  ($s2   >=   $s1), "!(s2 >= s1)");


    ok( $s2->is_subset("2001:db8:1:2::3:4", "2001:db8:5:6::7:8"),
        "s2 is subset of items");
    ok(!$s2->is_subset("2001:db8:1:2::3:4"),
        "s2 is not subset of item");
    ok( $s1->is_superset("2001:db8:1:2::3:4"),
        "s1 is superset of item");
    ok(!$s1->is_superset("2001:db8:1:2::3:4", "2001:db8:0:0::0:0"),
        "s1 is not superset of items");
  }
}

###

sub t_union {
  my($s1, $s2, $s3, $s4, $s5) = @_;
  cmp_ok($s3, '==', $s4, 's3 == s4');
  cmp_ok($s4, '==', $s5, 's4 == s5');
  cmp_ok($s5, '==', $s3, 's5 == s3');
  cmp_ok($s1, '<=', $s3, 's1 <= s3');
  cmp_ok($s2, '<=', $s3, 's2 <= s3');
  cmp_ok($s1, '<=', $s4, 's1 <= s4');
  cmp_ok($s2, '<=', $s4, 's2 <= s4');
  cmp_ok($s1, '<=', $s5, 's1 <= s5');
  cmp_ok($s2, '<=', $s5, 's2 <= s5');
  cmp_ok($s3->cardinality, '==', 3, "s3 3 items");
  cmp_ok($s4->cardinality, '==', 3, "s4 3 items");
  cmp_ok($s5->cardinality, '==', 3, "s5 3 items");
}

sub test_union {

  plan tests => 94;

  my($s1, $s2, $s3, $s4, $s5, $s6, $s7, $s8);

  $s1 = new_set();
  $s2 = new_set();

  $s1->add("1.2.3.4");
  $s1->add("5.6.7.8");
  $s2->add("5.6.7.8");
  $s2->add("9.10.11.12");

  $s3 = $s1->union($s2);
  $s4 = $s2->union($s1);
  $s5 = $s1->copy;
  $s5->update($s2);

  t_union($s1, $s2, $s3, $s4, $s5);

  $s3  = $s1 | $s2;
  $s4  = $s2 | $s1;
  $s5  = $s1->copy;
  $s5 |= $s2;

  t_union($s1, $s2, $s3, $s4, $s5);

  $s3 = $s1->union("5.6.7.8", "9.10.11.12");
  $s4 = $s2->union("1.2.3.4", "5.6.7.8");
  $s5 = $s1->copy;
  $s5->update("5.6.7.8", "9.10.11.12");

  t_union($s1, $s2, $s3, $s4, $s5);

  $s6 = $s1->copy;
  $s6->update(new_wc("10.x.x.10"));

  t_contains($s6, "10.10.10.10");
  t_contains($s6, "10.10.255.10");
  t_contains($s6, "10.0.0.10");
  t_contains($s6, "10.255.255.10");
  cmp_ok($s6->cardinality, '==', 0x10002, "s6 0x10002 items");

  $s7 = $s1->union($s2, new_wc("10.x.x.10"), "192.168.1.2", "192.168.3.4");
  $s8 = $s1->copy;
  $s8->update($s2, new_wc("10.x.x.10"), "192.168.1.2", "192.168.3.4");

  cmp_ok($s7, '==', $s8, "s7 == s8");
  t_contains   ($s8, "1.2.3.4");
  t_contains   ($s8, "5.6.7.8");
  t_contains   ($s8, "192.168.1.2");
  t_contains   ($s8, "10.10.10.10");
  t_contains   ($s8, "10.0.255.10");
  t_contains   ($s8, "10.0.0.10");
  t_contains   ($s8, "10.255.255.10");
  t_no_contains($s8, "10.10.10.0");
  t_no_contains($s8, "0.10.10.10");

  SKIP: {
    skip("ipv6 not enabled", 43) unless SILK_IPV6_ENABLED;

    $s1 = new_set();
    $s2 = new_set();

    $s1->add("2001:db8:1:2::3:4");
    $s1->add("2001:db8:5:6::7:8");
    $s2->add("2001:db8:5:6::7:8");
    $s2->add("2001:db8:9:10::11:12");

    $s3 = $s1->union($s2);
    $s4 = $s2->union($s1);
    $s5 = $s1->copy;
    $s5->update($s2);

    t_union($s1, $s2, $s3, $s4, $s5);

    $s3  = $s1 | $s2;
    $s4  = $s2 | $s1;
    $s5  = $s1->copy;
    $s5 |= $s2;

    t_union($s1, $s2, $s3, $s4, $s5);

    $s3 = $s1->union("2001:db8:5:6::7:8", "2001:db8:9:10::11:12");
    $s4 = $s2->union("2001:db8:1:2::3:4", "2001:db8:5:6::7:8");
    $s5 = $s1->copy;
    $s5->update("2001:db8:5:6::7:8", "2001:db8:9:10::11:12");

    t_union($s1, $s2, $s3, $s4, $s5);

    $s6 = $s1->copy;
    $s6->update(new_wc("::ffff:10.x.x.10"));

    t_contains   ($s6, "::ffff:10.10.10.10");
    t_contains   ($s6, "::ffff:10.0.255.10");
    t_contains   ($s6, "::ffff:10.0.0.10");
    t_contains   ($s6, "::ffff:10.255.255.10");
    t_no_contains($s6, "::ffff:10.10.10.0");
    t_no_contains($s6, "::ffff:0.10.10.10");
    cmp_ok($s6->cardinality, '==', 0x10002, "s6 0x10002 items");
  }
}

###

sub t_inter {
  my($s1, $s2, $s3, $s4, $s5) = @_;
  cmp_ok($s3, '==', $s4, 's3 == s4');
  cmp_ok($s4, '==', $s5, 's4 == s5');
  cmp_ok($s5, '==', $s3, 's5 == s3');
  cmp_ok($s1, '>=', $s3, 's1 >= s3');
  cmp_ok($s2, '>=', $s3, 's2 >= s3');
  cmp_ok($s1, '>=', $s4, 's1 >= s4');
  cmp_ok($s2, '>=', $s4, 's2 >= s4');
  cmp_ok($s1, '>=', $s5, 's1 >= s5');
  cmp_ok($s2, '>=', $s5, 's2 >= s5');
  cmp_ok($s3->cardinality, '==', 1, "s3 1 item");
  cmp_ok($s4->cardinality, '==', 1, "s4 1 item");
  cmp_ok($s5->cardinality, '==', 1, "s5 1 item");
}

sub test_intersection {

  plan tests => 75;

  my($s1, $s2, $s3, $s4, $s5, $s6, $s7);

  $s1 = new_set();
  $s2 = new_set();

  $s1->add("1.2.3.4");
  $s1->add("5.6.7.8");
  $s2->add("5.6.7.8");
  $s2->add("9.10.11.12");

  $s3 = $s1->intersection($s2);
  $s4 = $s2->intersection($s1);
  $s5 = $s1->copy;
  $s5->intersection_update($s2);

  t_inter($s1, $s2, $s3, $s4, $s5);

  $s3  = $s1 & $s2;
  $s4  = $s2 & $s1;
  $s5  = $s1->copy;
  $s5 &= $s2;

  t_inter($s1, $s2, $s3, $s4, $s5);

  $s3 = $s1->intersection("5.6.7.8", "9.10.11.12");
  $s4 = $s2->intersection("1.2.3.4", "5.6.7.8");
  $s5 = $s1->copy;
  $s5->intersection_update("5.6.7.8", "9.10.11.12");

  t_inter($s1, $s2, $s3, $s4, $s5);

  $s5 = $s1->copy;

  $s6 = $s1->intersection($s2, "5.6.7.8", "9.10.11.12");
  $s7 = $s1->copy;
  $s7->intersection_update($s2, "5.6.7.8", "9.10.11.12");

  cmp_ok($s6, '==', $s7, 's6 == s7');
  t_contains($s6, "5.6.7.8");
  cmp_ok($s6->cardinality, '==', 1, "s6 1 item");

  SKIP: {
    skip("ipv6 not enabled", 36) unless SILK_IPV6_ENABLED;

    $s1 = new_set();
    $s2 = new_set();

    $s1->add("2001:db8:1:2::3:4");
    $s1->add("2001:db8:5:6::7:8");
    $s2->add("2001:db8:5:6::7:8");
    $s2->add("2001:db8:9:10::11:12");

    $s3 = $s1->intersection($s2);
    $s4 = $s2->intersection($s1);
    $s5 = $s1->copy;
    $s5->intersection_update($s2);

    t_inter($s1, $s2, $s3, $s4, $s5);

    $s3  = $s1 & $s2;
    $s4  = $s2 & $s1;
    $s5  = $s1->copy;
    $s5 &= $s2;

    t_inter($s1, $s2, $s3, $s4, $s5);

    $s3 = $s1->intersection("2001:db8:5:6::7:8", "2001:db8:9:10::11:12");
    $s4 = $s2->intersection("2001:db8:1:2::3:4", "2001:db8:5:6::7:8");
    $s5 = $s1->copy;
    $s5->intersection_update("2001:db8:5:6::7:8", "2001:db8:9:10::11:12");

    t_inter($s1, $s2, $s3, $s4, $s5);
  }
}

###

sub t_diff {
  my($s1, $s2, $s3, $s4, $s5) = @_;
  cmp_ok($s3, '!=', $s4, 's3 != s4');
  cmp_ok($s5, '!=', $s4, 's5 != s4');
  cmp_ok($s1, '>=', $s3, 's1 >= s3');
  ok(!($s3 & $s2), 'disjoint(s3, s2)');
  cmp_ok($s1, '>=', $s5, 's1 >= s5');
  ok(!($s5 & $s2), 'disjoint(s5, s2)');
  cmp_ok($s2, '>=', $s4, 's2 >= s4');
  ok(!($s4 & $s1), 'disjoint(s4, s1)');
  cmp_ok($s3->cardinality, '==', 1, "s3 1 item");
  cmp_ok($s4->cardinality, '==', 1, "s4 1 item");
  cmp_ok($s5->cardinality, '==', 1, "s5 1 item");
}

sub test_difference {

  plan tests => 70;

  my($s1, $s2, $s3, $s4, $s5, $s6, $s7, $s8);

  $s1 = new_set();
  $s2 = new_set();

  $s1->add("1.2.3.4");
  $s1->add("5.6.7.8");
  $s2->add("5.6.7.8");
  $s2->add("9.10.11.12");

  $s3 = $s1->difference($s2);
  $s4 = $s2->difference($s1);
  $s5 = $s1->copy;
  $s5->difference_update($s2);

  t_diff($s1, $s2, $s3, $s4, $s5);

  $s3  = $s1 - $s2;
  $s4  = $s2 - $s1;
  $s5  = $s1->copy;
  $s5 -= $s2;

  t_diff($s1, $s2, $s3, $s4, $s5);

  $s3 = $s1->difference("5.6.7.8", "9.10.11.12");
  $s4 = $s2->difference("1.2.3.4", "5.6.7.8");
  $s5 = $s1->copy;
  $s5->difference_update("5.6.7.8", "9.10.11.12");

  t_diff($s1, $s2, $s3, $s4, $s5);

  $s6 = $s1->copy;
  $s6->add("7.7.7.7");
  $s6->add("8.8.8.8");
  $s7 = $s6->copy;
  $s8 = $s6->difference($s2, "8.8.8.8", "9.9.9.9");
  $s7->difference_update($s2, "8.8.8.8", "9.9.9.9");

  cmp_ok($s8, '==', $s7, 's8 == s7');
  cmp_ok($s7->cardinality, '==', 2, "s7 2 items");
  t_contains($s7, "1.2.3.4");
  t_contains($s7, "7.7.7.7");

  SKIP: {
    skip("ipv6 not enabled", 33) unless SILK_IPV6_ENABLED;

    $s1 = new_set();
    $s2 = new_set();

    $s1->add("2001:db8:1:2::3:4");
    $s1->add("2001:db8:5:6::7:8");
    $s2->add("2001:db8:5:6::7:8");
    $s2->add("2001:db8:9:10::11:12");

    $s3 = $s1->difference($s2);
    $s4 = $s2->difference($s1);
    $s5 = $s1->copy;
    $s5->difference_update($s2);

    t_diff($s1, $s2, $s3, $s4, $s5);

    $s3  = $s1 - $s2;
    $s4  = $s2 - $s1;
    $s5  = $s1->copy;
    $s5 -= $s2;

    t_diff($s1, $s2, $s3, $s4, $s5);

    $s3 = $s1->difference("2001:db8:5:6::7:8", "2001:db8:9:10::11:12");
    $s4 = $s2->difference("2001:db8:1:2::3:4", "2001:db8:5:6::7:8");
    $s5 = $s1->copy;
    $s5->difference_update("2001:db8:5:6::7:8", "2001:db8:9:10::11:12");

    t_diff($s1, $s2, $s3, $s4, $s5);
  }
}

###

sub t_symdiff {
  my($s1, $s2, $s3, $s4, $s5) = @_;
  cmp_ok($s3, '==', $s4, 's3 == s4');
  cmp_ok($s4, '==', $s5, 's4 == s5');
  cmp_ok($s5, '==', $s3, 's5 == s3');
  ok(!($s1 >= $s3), 's1 >= s3');
  ok(!($s2 >= $s3), 's2 >= s3');
  ok(!($s1 >= $s4), 's1 >= s4');
  ok(!($s2 >= $s4), 's2 >= s4');
  ok(!($s1 >= $s5), 's1 >= s5');
  ok(!($s2 >= $s5), 's2 >= s5');
  ok(!($s1 <= $s3), 's1 <= s3');
  ok(!($s2 <= $s3), 's2 <= s3');
  ok(!($s1 <= $s4), 's1 <= s4');
  ok(!($s2 <= $s4), 's2 <= s4');
  ok(!($s1 <= $s5), 's1 <= s5');
  ok(!($s2 <= $s5), 's2 <= s5');
  cmp_ok($s3->cardinality, '==', 2, 's3 2 items');
  cmp_ok($s4->cardinality, '==', 2, 's4 2 items');
  cmp_ok($s5->cardinality, '==', 2, 's5 2 items');
}

sub test_symdifference {

  plan tests => 108;

  my($s1, $s2, $s3, $s4, $s5);

  $s1 = new_set();
  $s2 = new_set();

  $s1->add("1.2.3.4");
  $s1->add("5.6.7.8");
  $s2->add("5.6.7.8");
  $s2->add("9.10.11.12");

  $s3 = $s1->symmetric_difference($s2);
  $s4 = $s2->symmetric_difference($s1);
  $s5 = $s1->copy;
  $s5->symmetric_difference_update($s2);

  t_symdiff($s1, $s2, $s3, $s4, $s5);

  $s3  = $s1 ^ $s2;
  $s4  = $s2 ^ $s1;
  $s5  = $s1->copy;
  $s5 ^= $s2;

  t_symdiff($s1, $s2, $s3, $s4, $s5);

  $s3 = $s1->symmetric_difference("5.6.7.8", "9.10.11.12");
  $s4 = $s2->symmetric_difference("1.2.3.4", "5.6.7.8");
  $s5 = $s1->copy;
  $s5->symmetric_difference_update("5.6.7.8", "9.10.11.12");

  t_symdiff($s1, $s2, $s3, $s4, $s5);

  SKIP: {
    skip("ipv6 not enabled", 54) unless SILK_IPV6_ENABLED;

    $s1 = new_set();
    $s2 = new_set();

    $s1->add("2001:db8:1:2::3:4");
    $s1->add("2001:db8:5:6::7:8");
    $s2->add("2001:db8:5:6::7:8");
    $s2->add("2001:db8:9:10::11:12");

    $s3 = $s1->symmetric_difference($s2);
    $s4 = $s2->symmetric_difference($s1);
    $s5 = $s1->copy;
    $s5->symmetric_difference_update($s2);

    t_symdiff($s1, $s2, $s3, $s4, $s5);

    $s3  = $s1 ^ $s2;
    $s4  = $s2 ^ $s1;
    $s5  = $s1->copy;
    $s5 ^= $s2;

    t_symdiff($s1, $s2, $s3, $s4, $s5);

    $s3 = $s1->symmetric_difference("2001:db8:5:6::7:8",
                                    "2001:db8:9:10::11:12");
    $s4 = $s2->symmetric_difference("2001:db8:1:2::3:4",
                                    "2001:db8:5:6::7:8");
    $s5 = $s1->copy;
    $s5->symmetric_difference_update("2001:db8:5:6::7:8",
                                     "2001:db8:9:10::11:12");

    t_symdiff($s1, $s2, $s3, $s4, $s5);
  }
}

###

sub test_pop {

  plan tests => 7;

  my $s = new_set("1.1.1.1", "2.2.2.2");
  cmp_ok($s->cardinality, '==', 2, "s 2 items");
  my $ip1 = $s->pop;
  cmp_ok($s->cardinality, '==', 1, "s 1 item");
  my $ip2 = $s->pop;
  cmp_ok($s->cardinality, '==', 0, "s 0 items");
  ok($ip1 == "1.1.1.1" || $ip1 == "2.2.2.2", "valid item");
  ok($ip2 == "1.1.1.1" || $ip2 == "2.2.2.2", "valid item");
  cmp_ok($ip1, '!=', $ip2, "items differ");
  ok(! defined($s->pop), "empty pop");
}

###

sub test_iteration {

  plan tests => 34;

  my @addrs = map { new_ip($_) }
              ("1.2.3.4", "1.2.3.5", "1.2.3.6", "1.2.3.7",
               "1.2.3.8", "1.2.3.9", "0.0.0.0");
  
  my %keys;
  $keys{$_} = $_ foreach @addrs;

  my $s = new_set(@addrs);

  my $count = 0;
  my $iter = $s->iter;
  while (my $x = $iter->()) {
    t_contains($s, $x);
    ok(exists $keys{$x}, "exists $x");
    $count++;
  }
  cmp_ok($count, '==', @addrs, "count match");
  my %cidrs;
  $iter = $s->iter_cidr;
  while (my $block = $iter->()) {
    $cidrs{$block->[0]} = $block->[1];
  }
  cmp_ok(keys %cidrs, '==', 3, "cidr count match");
  my %blocks = (
    '0.0.0.0' => 32,
    '1.2.3.4' => 30,
    '1.2.3.8' => 31,
  );
  is_deeply(\%cidrs, \%blocks, "cidr block match");

  SKIP: {
    skip("ipv6 not enabled", 17) unless SILK_IPV6_ENABLED;

    my @addrs = map { new_ip($_) }
                    ("2001:db8:1:2::3:4", "2001:db8:1:2::3:5",
                     "2001:db8:1:2::3:6", "2001:db8:1:2::3:7",
                     "2001:db8:1:2::3:8", "2001:db8:1:2::3:9",
                     "2001:db8::");
  
    my %keys;
    $keys{$_} = $_ foreach @addrs;

    my $s = new_set(@addrs);

    my $count = 0;
    my $iter = $s->iter;
    while (my $x = $iter->()) {
      t_contains($s, $x);
      ok(exists $keys{$x}, "exists $x");
      $count++;
    }
    cmp_ok($count, '==', @addrs, "count match");
    my %cidrs;
    $iter = $s->iter_cidr;
    while (my $block = $iter->()) {
      $cidrs{$block->[0]} = $block->[1];
    }
    cmp_ok(keys %cidrs, '==', 3, "cidr count match");
    my %blocks = (
      '2001:db8::'        => 128,
      '2001:db8:1:2::3:4' => 126,
      '2001:db8:1:2::3:8' => 127,
    );
    is_deeply(\%cidrs, \%blocks, "cidr block match");
  }
}

###

sub test_io {

  plan tests => 8;

  my($s1, $s2, $fn);

  $fn = t_tmp_filename();

  $s1 = new_set("1.2.3.4", "1.2.3.5", "1.2.3.6", "1.2.3.7",
                "1.2.3.8", "1.2.3.9", "0.0.0.0");
  eval { $s1->save($fn) };
  ok(!$@, "save rwset file");
  ok(-f $fn, "rwset file exists");
  eval { $s2 = SILK_IPSET_CLASS->load($fn) };
  ok(!$@, "load rwset file");
  cmp_ok($s1, '==', $s2, "sets match");
  unlink $fn;

  SKIP: {
    skip("ipv6 not enabled", 4) unless SILK_IPV6_ENABLED;

    $s1 = new_set("2001:db8:1:2::3:4", "2001:db8:1:2::3:5",
                  "2001:db8:1:2::3:6", "2001:db8:1:2::3:7",
                  "2001:db8:1:2::3:8", "2001:db8:1:2::3:9",
                  "2001:db8::");
    eval { $s1->save($fn) };
    ok(!$@, "save rwset file");
    ok(-f $fn, "rwset file exists");
    eval { $s2 = SILK_IPSET_CLASS->load($fn) };
    ok(!$@, "load rwset file");
    cmp_ok($s1, '==', $s2, "sets match");
    unlink $fn;
  }
}

###

sub test_all {
  subtest "construction"  => \&test_construction;
  subtest "supports ipv6" => \&test_supports_ipv6;
  subtest "add/contain"   => \&test_add_contain;
  subtest "promotion"     => \&test_promotion;
  subtest "copy"          => \&test_copy;
  subtest "remove"        => \&test_remove;
  subtest "clear"         => \&test_clear;
  subtest "cardinality"   => \&test_cardinality;
  subtest "add types"     => \&test_add_types;
  subtest "supersub"      => \&test_supersub;
  subtest "union"         => \&test_union;
  subtest "intersection"  => \&test_intersection;
  subtest "difference"    => \&test_difference;
  subtest "symdifference" => \&test_symdifference;
  subtest "popper"        => \&test_pop;
  subtest "iteration"     => \&test_iteration;
  subtest "io"            => \&test_io;
}

test_all();

###
