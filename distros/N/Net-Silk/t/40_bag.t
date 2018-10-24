use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use silktest;

use Test::More tests => 32;

use Net::Silk qw( :basic );

use Math::Int64  qw( string_to_uint64 );
use Math::Int64::die_on_overflow;

use Scalar::Util qw( looks_like_number );

BEGIN { use_ok( SILK_BAG_CLASS )  }

my %bag_types = (
  custom   => 'custom',
  any_ipv4 => 'any-IPv4',
  any_ipv6 => 'any-IPv6',
  any_port => 'any-port',
  sport    => 'sPort',
  dport    => 'dPort',
  sipv6    => 'sIPv6',
  dipv4    => 'dIPv4',
  records  => 'records',
);

sub new_set     { SILK_IPSET_CLASS      ->new(@_)    }
sub new_ip      { SILK_IPADDR_CLASS     ->new(shift) }
sub new_ipv6    { SILK_IPV6ADDR_CLASS   ->new(shift) }
sub new_wc      { SILK_IPWILDCARD_CLASS ->new(shift) }

sub new_bag {
  my %vals = @_;
  my $b = SILK_BAG_CLASS->new;
  $b->update(\%vals) if %vals;
  $b;
}

sub new_ip_bag {
  my %vals = @_;
  my $b = SILK_BAG_CLASS->new_ipaddr;
  while (my($k, $v) = each %vals) {
    $k = new_ip($k);
    $b->set($k, $v);
  }
  $b;
}

sub new_ipv4_bag {
  my %vals = @_;
  my $b = SILK_BAG_CLASS->new_ipv4addr;
  while (my($k, $v) = each %vals) {
    $k = new_ip($k);
    $b->set($k, $v);
  }
  $b;
}

sub new_int_bag {
  my %vals = @_;
  my $b = SILK_BAG_CLASS->new_integer;
  while (my($k, $v) = each %vals) {
    $k = int($k);
    $b->set($k, $v);
  }
  $b;
}

sub t_make_bag {
  my $b = new_bag(@_);
  isa_ok($b, SILK_BAG_CLASS);
  $b;
}

sub t_make_ip_bag {
  my $b = new_ip_bag(@_);
  isa_ok($b, SILK_BAG_CLASS);
  SILK_IPV6_ENABLED ? is_deeply([$b->_bag_info],
                                [33, 16, 16, 'any-IPv6', 255, 8, 8, 'custom'])
                    : is_deeply([$b->_bag_info],
                                [32,  4, 16, 'any-IPv4', 255, 8, 8, 'custom']);
  $b;
}

sub t_make_int_bag {
  my $b = new_int_bag(@_);
  isa_ok($b, SILK_BAG_CLASS);
  is_deeply([$b->_bag_info],
            [255, 4, 4, 'custom', 255, 8, 8, 'custom']);
  $b;
}

sub t_build_custom_bag { new_ok(SILK_BAG_CLASS, \@_) }

sub build_custom_bag { SILK_BAG_CLASS->new(@_) }

###

sub simple_ip_bag {
  my $b = new_ipv4_bag();
  $b->add($_) foreach (("1.1.1.1", "2.2.2.2", "3.3.3.3", "4.4.4.4",
                        "255.255.255.255"));
  $b->incr("10.10.10.10", 5);
  $b;
}

sub simple_ipv6_bag {
  my $b = new_ip_bag();
  $b->add($_) foreach (("::1", "2::", "3::4", "5::6.7.8.9",
                        "::ffff:1.1.1.1",
                        "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"));
  $b->incr("10:10:10:10:10:10:10:10", 5);
  $b;
}

sub simple_int_bag {
  my $b = new_int_bag();
  $b->add(1, 2, 3, 4, 0xffffffff);
  $b->incr(10, 5);
  $b;
}

sub simple_bags {
  my $b1 = new_int_bag(
    1  =>  5,
    2  => 10,
    5  =>  5,
    6  => 10,
    9  =>  5,
    10 => 10,
    11 =>  1,
    12 => "0xfffffffffffffffd",
  );
  my $b2 = new_int_bag(
    1  =>  5,
    2  => 10,
    3  =>  5,
    4  => 10,
    9  => 10,
    10 =>  5,
    11 => "0xfffffffffffffffd",
    12 =>  1,
  );
  return($b1, $b2);
}

###

sub test_construction {

  plan tests => 13;

  my($b, $fn);

  $b  = t_make_bag();
  $fn = t_tmp_filename();
  eval { $b->save($fn) };
  ok(!$@, "save bag file");
  ok(-f $fn, "bag file exists");
  eval { $b = SILK_BAG_CLASS->load($fn) };
  ok(!$@, "load bag file");
  isa_ok($b, SILK_BAG_CLASS);
  unlink $fn;
  $b = new_int_bag();
  eval { $b->save($fn) };
  ok(!$@, "save bag file");
  ok(-f $fn, "bag file exists");
  eval { $b = SILK_BAG_CLASS->load($fn) };
  ok(!$@, "load bag file");
  unlink $fn;
  t_make_ip_bag(
    "1.1.1.1"         => 1,
    "2.2.2.2"         => 2,
    "255.255.255.255" => 1,
  );
  t_make_int_bag(
    1 => 1,
    2 => 2,
    0xFFFFFFFF => 1,
  );
  t_build_custom_bag(
    key_type     => $bag_types{custom},
    key_len      => 2,
    counter_type => $bag_types{custom},
    counter_len  => 8,
  );
}

###

sub test_io {

  plan tests => 18;

  my($b1, $b2, $fn);

  $fn = t_tmp_filename();

  $b1 = simple_int_bag();
  eval { $b1->save($fn) };
  ok(!$@, "save bag file");
  ok(-f $fn, "bag file exists");
  eval { $b2 = SILK_BAG_CLASS->load($fn) };
  ok(!$@, "load bag file");
  isa_ok($b2, SILK_BAG_CLASS);
  cmp_ok($b1, '==', $b2, "bags match");
  is_deeply([$b1->_bag_info], [$b2->_bag_info], "meta match");
  unlink($fn);
  $b1 = simple_ip_bag();
  eval { $b1->save($fn) };
  ok(!$@, "save bag file");
  ok(-f $fn, "bag file exists");
  eval { $b2 = SILK_BAG_CLASS->load($fn) };
  ok(!$@, "load bag file");
  isa_ok($b2, SILK_BAG_CLASS);
  cmp_ok($b1, '==', $b2, "bags match");
  is_deeply([$b1->_bag_info], [$b2->_bag_info], "meta match");
  unlink($fn);

  SKIP: {
    skip("ipv6 not enabled", 6) unless SILK_IPV6_ENABLED;
    $b1 = simple_ipv6_bag();
    eval { $b1->save($fn) };
    ok(!$@, "save bag file");
    ok(-f $fn, "bag file exists");
    eval { $b2 = SILK_BAG_CLASS->load($fn) };
    ok(!$@, "load bag file");
    isa_ok($b2, SILK_BAG_CLASS);
    cmp_ok($b1, '==', $b2, "bags match");
    is_deeply([$b1->_bag_info], [$b2->_bag_info], "meta match");
    unlink($fn);
  }
}

###

sub t_ag_int_to_ref {
  my($b, $r) = @_;

  my $v;

  $v = $r->{0} || 0;
  $v ? ok(  $b->contains(0), 'bag contains 0')
     : ok(! $b->contains(0), 'bag missing 0');
  $v ? ok(  exists $b->{0},  'hash contains 0')
     : ok(! exists $b->{0},  'hash missing 0');
  cmp_ok($b->get(0), '==', $v, "bag count 0:$v");
  cmp_ok($b->{0},    '==', $v, "hash count 0:$v");

  $v = $r->{1} || 0;
  $v ? ok(  $b->contains(1), 'bag contains 1')
     : ok(! $b->contains(1), 'bag missing 1');
  $v ? ok(  exists $b->{1},  'hash contains 1')
     : ok(! exists $b->{1},  'hash missing 1');
  cmp_ok($b->get(1), '==', $v, "bag count 1:$v");
  cmp_ok($b->{1},    '==', $v, "hash count 1:$v");

  $v = $r->{3} || 0;
  $v ? ok(  $b->contains(3), 'bag contains 3')
     : ok(! $b->contains(3), 'bag missing 3');
  $v ? ok(  exists $b->{3},  'hash contains 3')
     : ok(! exists $b->{3},  'hash missing 3');
  cmp_ok($b->get(3), '==', $v, "bag count 3:$v");
  cmp_ok($b->{3},    '==', $v, "hash count 3:$v");

  $v = $r->{0xffffffff} || 0;
  $v ? ok(  $b->contains(0xffffffff), 'bag contains 0xffffffff')
     : ok(! $b->contains(0xffffffff), 'bag missing 0xffffffff');
  $v ? ok(  exists $b->{0xffffffff},  'hash contains 0xffffffff')
     : ok(! exists $b->{0xffffffff},  'hash missing 0xffffffff');
  cmp_ok($b->get(0xffffffff), '==', $v, "bag count 0xffffffff:$v");
  cmp_ok($b->{0xffffffff},    '==', $v, "hash count 0xffffffff:$v");
}

sub t_ag_ip_to_ref {
  my($b, $r) = @_;

  my($v, $k);

  $k = new_ip('0.0.0.0');
  $v = $r->{$k} || 0;
  $v ? ok(  $b->contains($k), "bag contains $k")
     : ok(! $b->contains($k), "bag missing $k");
  $v ? ok(  exists $b->{$k},  "hash contains $k")
     : ok(! exists $b->{$k},  "hash missing $k");
  cmp_ok($b->get($k), '==', $v, "bag count $k:$v");
  cmp_ok($b->{$k},    '==', $v, "hash count $k:$v");

  $k = '1.1.1.1';
  $v = $r->{$k} || 0;
  $v ? ok(  $b->contains($k), "bag contains $k")
     : ok(! $b->contains($k), "bag missing $k");
  $v ? ok(  exists $b->{$k},  "hash contains $k")
     : ok(! exists $b->{$k},  "hash missing $k");
  cmp_ok($b->get($k), '==', $v, "bag count $k:$v");
  cmp_ok($b->{$k},    '==', $v, "hash count $k:$v");

  SKIP: {
    skip("ipv6 not enabled", 4) unless SILK_IPV6_ENABLED;
    $k = new_ip('::ffff:1.1.1.1');
    $v ? ok(  $b->contains($k), "bag contains $k")
       : ok(! $b->contains($k), "bag missing $k");
    $v ? ok(  exists $b->{$k},  "hash contains $k")
       : ok(! exists $b->{$k},  "hash missing $k");
    cmp_ok($b->get($k), '==', $v, "bag count $k:$v");
    cmp_ok($b->{$k},    '==', $v, "hash count $k:$v");
  }

  $k = '255.255.255.255';
  $v = $r->{$k} || 0;
  $v ? ok(  $b->contains($k), "bag contains $k")
     : ok(! $b->contains($k), "bag missing $k");
  $v ? ok(  exists $b->{$k},  "hash contains $k")
     : ok(! exists $b->{$k},  "hash missing $k");
  cmp_ok($b->get($k), '==', $v, "bag count $k:$v");
  cmp_ok($b->{$k},    '==', $v, "hash count $k:$v");

  SKIP: {
    skip("ipv6 not enabled", 4) unless SILK_IPV6_ENABLED;
    $k = '1::';
    $v = $r->{$k} || 0;
    $v ? ok(  $b->contains($k), "bag contains $k")
       : ok(! $b->contains($k), "bag missing $k");
    $v ? ok(  exists $b->{$k},  "hash contains $k")
       : ok(! exists $b->{$k},  "hash missing $k");
    cmp_ok($b->get($k), '==', $v, "bag count $k:$v");
    cmp_ok($b->{$k},    '==', $v, "hash count $k:$v");
  }

}

sub test_addget {

  #plan tests => 197;
  plan tests => 196;

  my $b;
  my $r = {};

  $b = new_int_bag();

  t_ag_int_to_ref($b, $r);

  $r->{1} += 1;
  $b->add(1);
  t_ag_int_to_ref($b, $r);

  $r->{1} += 1;
  $b->add(1);
  t_ag_int_to_ref($b, $r);

  $r->{0xffffffff} += 1;
  $b->add(0xffffffff);
  t_ag_int_to_ref($b, $r);

  $r->{2} += 1;
  $r->{3} += 1;
  $b->add(2, 3);
  t_ag_int_to_ref($b, $r);

  $r->{2} += 1;
  $r->{3} += 1;
  $b->add(2, 3);
  t_ag_int_to_ref($b, $r);

  $b  = new_ip_bag();
  %$r = ();
  t_ag_ip_to_ref($b, $r);

  $r->{"1.1.1.1"} += 1;
  $b->add("1.1.1.1");
  t_ag_ip_to_ref($b, $r);

  $r->{"1.1.1.1"} += 1;
  $b->add("1.1.1.1");
  t_ag_ip_to_ref($b, $r);

  $r->{"255.255.255.255"} += 1;
  $b->add("255.255.255.255");
  t_ag_ip_to_ref($b, $r);

  SKIP: {
    skip("ipv6 not enabled", 20) unless SILK_IPV6_ENABLED;
    $r->{'1::'} += 1;
    $b->add('1::');
    t_ag_ip_to_ref($b, $r);
  }

  #eval { $b->add(0) };
  #ok($@, "no add int to ip bag: $@");
}

###

sub test_copy {

  plan tests => 14;

  my($b1, $b2, $b3);

  $b1 = new_int_bag();
  $b2 = $b1;
  $b3 = $b1->copy;

  cmp_ok($b1, '==', $b2, 'b1 == b2');
  cmp_ok($b2, '==', $b3, 'b2 == b3');
  cmp_ok($b3, '==', $b1, 'b3 == b1');
  is  ("$b1", "$b2", 'b1 is b2');
  isnt("$b1", "$b3", 'b1 is not b3');
  $b1->add(0);
  cmp_ok($b1, '==', $b2, 'b1 == b2');
  cmp_ok($b2, '!=', $b3, 'b2 != b3');
  $b1->add(1);
  $b1->add(2);
  $b3 = $b1->copy;
  cmp_ok($b1, '==', $b2, 'b1 == b2');
  cmp_ok($b2, '==', $b3, 'b2 == b3');
  cmp_ok($b3, '==', $b1, 'b3 == b1');
  is  ("$b1", "$b2", 'b1 is b2');
  isnt("$b1", "$b3", 'b1 is not b3');
  $b1->add(0);
  cmp_ok($b1, '==', $b2, 'b1 == b2');
  cmp_ok($b2, '!=', $b3, 'b2 != b3');

}

###

sub test_remove {

  plan tests => 70;

  my $b1;

  $b1 = new_int_bag();
  $b1->add(1, 2, 3);
  ok(  $b1->contains(1), 'bag contains 1');
  ok(  $b1->contains(2), 'bag contains 2');
  ok(  $b1->contains(3), 'bag contains 3');
  ok(  exists $b1->{1}, 'hash 1 exists');
  ok(  exists $b1->{2}, 'hash 2 exists');
  ok(  exists $b1->{3}, 'hash 3 exists');

  $b1->remove(1);

  ok(! $b1->contains(1), 'bag missing 1');
  ok(  $b1->contains(2), 'bag contains 2');
  ok(  $b1->contains(3), 'bag contains 3');
  ok(! exists $b1->{1}, 'hash 1 no exist');
  ok(  exists $b1->{2}, 'hash 2 exists');
  ok(  exists $b1->{3}, 'hash 3 exists');

  $b1->add(1);
  $b1->add(1);
  $b1->remove(1);

  ok(  $b1->contains(1), 'bag contains 1');
  ok(  $b1->contains(2), 'bag contains 2');
  ok(  $b1->contains(3), 'bag contains 3');
  ok(  exists $b1->{1}, 'hash 1 exists');
  ok(  exists $b1->{2}, 'hash 2 exists');
  ok(  exists $b1->{3}, 'hash 3 exists');

  $b1->remove(1);

  ok(! $b1->contains(1), 'bag missing 1');
  ok(  $b1->contains(2), 'bag contains 2');
  ok(  $b1->contains(3), 'bag contains 3');
  ok(! exists $b1->{1}, 'hash 1 no exist');
  ok(  exists $b1->{2}, 'hash 2 exists');
  ok(  exists $b1->{3}, 'hash 3 exists');

  $b1->remove(2, 3);

  ok(! $b1->contains(1), 'bag missing 1');
  ok(! $b1->contains(2), 'bag missing 2');
  ok(! $b1->contains(3), 'bag missing 3');
  ok(! exists $b1->{1}, 'hash 1 missing');
  ok(! exists $b1->{2}, 'hash 2 missing');
  ok(! exists $b1->{3}, 'hash 3 missing');

  $b1->add(1, 3);

  ok(  $b1->contains(1), 'bag contains 1');
  ok(! $b1->contains(2), 'bag missing 2');
  ok(  $b1->contains(3), 'bag contains 3');
  ok(  exists $b1->{1}, 'hash 1 exists');
  ok(! exists $b1->{2}, 'hash 2 no exists');
  ok(  exists $b1->{3}, 'hash 3 exists');
  
  $b1->remove(1, 3);

  ok(! $b1->contains(1), 'bag missing 1');
  ok(! $b1->contains(2), 'bag missing 2');
  ok(! $b1->contains(3), 'bag missing 3');
  ok(! exists $b1->{1}, 'hash 1 missing');
  ok(! exists $b1->{2}, 'hash 2 missing');
  ok(! exists $b1->{3}, 'hash 3 missing');

  #      self.assert_(1 not in b)
  #      self.assert_(2 not in b)
  #      self.assert_(3 not in b)
  #      self.assertRaises(OverflowError, b.remove, 1)
  #      self.assertRaises(TypeError, b.remove, "2")
  #      self.assertRaises(TypeError, b.remove, "0.0.0.2")
  #      self.assertRaises(TypeError, b.remove, IPAddr("0.0.0.2"))

  $b1 = simple_int_bag();

  cmp_ok($b1->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b1->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b1->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b1->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b1->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b1->get(10),         '==', 5, 'get(10):5');
  cmp_ok($b1->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b1->remove(10);

  cmp_ok($b1->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b1->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b1->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b1->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b1->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b1->get(10),         '==', 4, 'get(10):4');
  cmp_ok($b1->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b1->remove(1, 3);

  cmp_ok($b1->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b1->get(1),          '==', 0, 'get(1):0');
  cmp_ok($b1->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b1->get(3),          '==', 0, 'get(3):0');
  cmp_ok($b1->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b1->get(10),         '==', 4, 'get(10):4');
  cmp_ok($b1->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b1->remove(10, 0xffffffff);

  cmp_ok($b1->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b1->get(1),          '==', 0, 'get(1):0');
  cmp_ok($b1->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b1->get(3),          '==', 0, 'get(3):0');
  cmp_ok($b1->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b1->get(10),         '==', 3, 'get(10):3');
  cmp_ok($b1->get(0xffffffff), '==', 0, 'get(0xffffffff):0');

}

###

sub test_simple_get {

  plan tests => 18;

  my $b;

  $b = simple_int_bag();

  cmp_ok($b->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b->get(0xffffffff), '==', 1, 'get(0xffffff):1');

  #self.assertRaises(IndexError, b.__getitem__, -1)
  #self.assertRaises(IndexError, b.__getitem__, 0x100000000)
  #self.assertRaises(TypeError, b.__getitem__, "1")

  $b = simple_ip_bag();

  cmp_ok($b->get('0.0.0.0'),         '==', 0, 'get(0.0.0.0):0');
  cmp_ok($b->get('1.1.1.1'),         '==', 1, 'get(1.1.1.1):1');
  cmp_ok($b->get('2.2.2.2'),         '==', 1, 'get(2.2.2.2):1');
  cmp_ok($b->get('9.9.9.9'),         '==', 0, 'get(9.9.9.9):0');
  cmp_ok($b->get('10.10.10.10'),     '==', 5, 'get(10.10.10.10):5');
  cmp_ok($b->get('255.255.255.255'), '==', 1, 'get(255.255.255.255):1');

  #self.assertRaises(TypeError, b.__getitem__, -1)
  #self.assertRaises(TypeError, b.__getitem__, 0x100000000)
  #self.assertRaises(TypeError, b.__getitem__, 1)
  #self.assertRaises(TypeError, b.__getitem__, "1.1.1.1")

  SKIP: {
    skip("ipv6 not enabled", 7) unless SILK_IPV6_ENABLED;

    $b = simple_ipv6_bag();

    cmp_ok($b->get('::0'),         '==', 0, 'get(::0):0');
    cmp_ok($b->get('::1'),         '==', 1, 'get(::1):1');
    cmp_ok($b->get('2::'),         '==', 1, 'get(2::):1');
    cmp_ok($b->get('::9'),         '==', 0, 'get(::9):0');
    cmp_ok($b->get('1.1.1.1'),     '==', 1, 'get(1.1.1.1):1');
    cmp_ok($b->get('10:10:10:10:10:10:10:10'),
                                   '==', 5,
                                   'get(10:10:10:10:10:10:10:10):5');
    cmp_ok($b->get('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff'),
                                   '==', 1,
                   'get(ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff):1');

    #self.assertRaises(TypeError, b.__getitem__, -1)
    #self.assertRaises(TypeError, b.__getitem__, 0x100000000)
    #self.assertRaises(TypeError, b.__getitem__, 1)
    #self.assertRaises(TypeError, b.__getitem__, "1.1.1.1")
  }
}

###

sub test_val_type {
  plan tests => 19;
  my $b = simple_int_bag();
  for my $kv (<$b>) {
    ok(looks_like_number($kv->[0]), "$kv->[0] isa int");
  }
  $b = simple_ip_bag();
  for my $kv (<$b>) {
    isa_ok($kv->[0], SILK_IPV4ADDR_CLASS);
  }
  SKIP: {
    skip("ipv6 not enabled", 7) unless SILK_IPV6_ENABLED;
    $b = simple_ipv6_bag();
    for my $kv (<$b>) {
      isa_ok($kv->[0], SILK_IPV6ADDR_CLASS);
    }
  }
}

###

sub test_intersect {

  plan tests => 77;

  my($b1, $b2, $b3, $x, $y);

  $b1 = simple_int_bag();

  $b2 = $b1->intersect([2, 3]);
  cmp_ok($b2->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b2->get(1),          '==', 0, 'get(1):0');
  cmp_ok($b2->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b2->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b2->get(4),          '==', 0, 'get(4):0');
  cmp_ok($b2->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b2->get(10),         '==', 0, 'get(10):0');
  cmp_ok($b2->get(0xffffffff), '==', 0, 'get(0xffffffff):0');

  $b2 = $b1->intersect({2 => 1, 3 => 1});
  cmp_ok($b2->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b2->get(1),          '==', 0, 'get(1):0');
  cmp_ok($b2->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b2->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b2->get(4),          '==', 0, 'get(4):0');
  cmp_ok($b2->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b2->get(10),         '==', 0, 'get(10):0');
  cmp_ok($b2->get(0xffffffff), '==', 0, 'get(0xffffffff):0');

  $b2 = $b1->intersect([2, 3, 10]);
  cmp_ok($b2->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b2->get(1),          '==', 0, 'get(1):0');
  cmp_ok($b2->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b2->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b2->get(4),          '==', 0, 'get(4):0');
  cmp_ok($b2->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b2->get(10),         '==', 5, 'get(10):5');
  cmp_ok($b2->get(0xffffffff), '==', 0, 'get(0xffffffff):0');

  $b1 = simple_ip_bag();

  $x = new_set('2.2.2.2', '4.4.4.4', '10.10.10.10');

  $b2 = $b1->intersect($x);
  cmp_ok($b2->get('0.0.0.0'),         '==', 0, 'get(0.0.0.0):0');
  cmp_ok($b2->get('1.1.1.1'),         '==', 0, 'get(1.1.1.1):0');
  cmp_ok($b2->get('2.2.2.2'),         '==', 1, 'get(2.2.2.2):1');
  cmp_ok($b2->get('3.3.3.3'),         '==', 0, 'get(3.3.3.3):0');
  cmp_ok($b2->get('4.4.4.4'),         '==', 1, 'get(4.4.4.4):1');
  cmp_ok($b2->get('5.5.5.5'),         '==', 0, 'get(5.5.5.5):0');
  cmp_ok($b2->get('9.9.9.9'),         '==', 0, 'get(9.9.9.9):0');
  cmp_ok($b2->get('10.10.10.10'),     '==', 5, 'get(10.10.10.10):5');
  cmp_ok($b2->get('255.255.255.255'), '==', 0, 'get(255.255.255.255):0');

  $y = new_wc('10.10.10.x');

  $b2 = $b1->intersect($y);

  cmp_ok($b2->get('0.0.0.0'),         '==', 0, 'get(0.0.0.0):0');
  cmp_ok($b2->get('1.1.1.1'),         '==', 0, 'get(1.1.1.1):0');
  cmp_ok($b2->get('2.2.2.2'),         '==', 0, 'get(2.2.2.2):0');
  cmp_ok($b2->get('3.3.3.3'),         '==', 0, 'get(3.3.3.3):0');
  cmp_ok($b2->get('4.4.4.4'),         '==', 0, 'get(4.4.4.4):0');
  cmp_ok($b2->get('5.5.5.5'),         '==', 0, 'get(5.5.5.5):0');
  cmp_ok($b2->get('9.9.9.9'),         '==', 0, 'get(9.9.9.9):0');
  cmp_ok($b2->get('10.10.10.10'),     '==', 5, 'get(10.10.10.10):5');
  cmp_ok($b2->get('255.255.255.255'), '==', 0, 'get(255.255.255.255):0');

  SKIP: {
    skip("ipv6 not enabled", 8) unless SILK_IPV6_ENABLED;

    $b1 = simple_ipv6_bag();

    $x  = new_set("::1", "::2", "1.1.1.1", "10:10:10:10:10:10:10:10");
    $b2 = $b1->intersect($x);
    cmp_ok($b2->get('::1'),         '==', 1, 'get(::1):1');
    cmp_ok($b2->get('::2'),         '==', 0, 'get(::2):0');
    cmp_ok($b2->get('2::'),         '==', 0, 'get(2::):0');
    cmp_ok($b2->get('3::4'),        '==', 0, 'get(3::4):0');
    cmp_ok($b2->get('5::6.7.8.9'),  '==', 0, 'get(5::6.7.8.9):0');
    cmp_ok($b2->get('1.1.1.1'),     '==', 1, 'get(1.1.1.1):1');
    cmp_ok($b2->get('10:10:10:10:10:10:10:10'),
                                    '==', 5,
                'get(10:10:10:10:10:10:10:10):5');
    cmp_ok($b2->get('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff'),
                                   '==', 0,
                'get(ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff):0');
  }

  ($b1, $b2) = simple_bags();

  $b3 = $b1->intersect($b2);
  cmp_ok($b3->get(1),          '==',  5, 'get(1):5');
  cmp_ok($b3->get(2),          '==', 10, 'get(2):10');
  cmp_ok($b3->get(3),          '==',  0, 'get(3):0');
  cmp_ok($b3->get(4),          '==',  0, 'get(4):0');
  cmp_ok($b3->get(5),          '==',  0, 'get(5):0');
  cmp_ok($b3->get(6),          '==',  0, 'get(6):0');
  cmp_ok($b3->get(7),          '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),          '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),          '==',  5, 'get(9):5');
  cmp_ok($b3->get(10),         '==', 10, 'get(10):10');
  cmp_ok($b3->get(11),         '==',  1, 'get(11):1');
  cmp_ok($b3->get(12), '==', string_to_uint64('0xfffffffffffffffd'),
                                      'get(12):0xfffffffffffffffd');

  $b3 = $b2->intersect($b1);
  cmp_ok($b3->get(1),          '==',  5, 'get(1):5');
  cmp_ok($b3->get(2),          '==', 10, 'get(2):10');
  cmp_ok($b3->get(3),          '==',  0, 'get(3):0');
  cmp_ok($b3->get(4),          '==',  0, 'get(4):0');
  cmp_ok($b3->get(5),          '==',  0, 'get(5):0');
  cmp_ok($b3->get(6),          '==',  0, 'get(6):0');
  cmp_ok($b3->get(7),          '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),          '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),          '==', 10, 'get(9):10');
  cmp_ok($b3->get(10),         '==',  5, 'get(10):5');
  cmp_ok($b3->get(11), '==', string_to_uint64('0xfffffffffffffffd'),
                                      'get(11):0xfffffffffffffffd');
  cmp_ok($b3->get(12),         '==',  1, 'get(12):1');

  $b3 = $b1->intersect([1, 2]);

  my %check = (1 => 5, 2 => 10);

  my $c = 0;
  my $i = $b3->iter;
  while (my $r = $i->()) {
    cmp_ok($r->[1], '==', $check{$r->[0]}, "b3 item $c match");
    ++$c;
  }
  cmp_ok($b3->cardinality, '==', keys %check, 'b3 item count');

}


###

sub test_delete {

  plan tests => 35;

  my($b);

  $b = simple_int_bag();

  cmp_ok($b->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b->get(10),         '==', 5, 'get(10):5');
  cmp_ok($b->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b->del(2);

  cmp_ok($b->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b->get(2),          '==', 0, 'get(2):0');
  cmp_ok($b->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b->get(10),         '==', 5, 'get(10):5');
  cmp_ok($b->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  delete $b->{10};

  cmp_ok($b->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b->get(2),          '==', 0, 'get(2):0');
  cmp_ok($b->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b->get(10),         '==', 0, 'get(10):0');
  cmp_ok($b->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b->del(0xffffffff);

  cmp_ok($b->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b->get(2),          '==', 0, 'get(2):0');
  cmp_ok($b->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b->get(10),         '==', 0, 'get(10):0');
  cmp_ok($b->get(0xffffffff), '==', 0, 'get(0xffffffff):0');

  delete $b->{0};

  cmp_ok($b->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b->get(2),          '==', 0, 'get(2):0');
  cmp_ok($b->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b->get(10),         '==', 0, 'get(10):0');
  cmp_ok($b->get(0xffffffff), '==', 0, 'get(0xffffffff):0');

}

###

sub test_set {

  plan tests => 28;

  my($b);

  $b = simple_int_bag();

  cmp_ok($b->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b->get(10),         '==', 5, 'get(10):5');
  cmp_ok($b->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b->set(2, 5);

  cmp_ok($b->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b->get(2),          '==', 5, 'get(2):5');
  cmp_ok($b->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b->get(10),         '==', 5, 'get(10):5');
  cmp_ok($b->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b->{10} = 0;

  cmp_ok($b->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b->get(2),          '==', 5, 'get(2):5');
  cmp_ok($b->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b->get(10),         '==', 0, 'get(10):0');
  cmp_ok($b->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b->set(0xffffffff, 15);

  cmp_ok($b->get(0),          '==',  0, 'get(0):0');
  cmp_ok($b->get(1),          '==',  1, 'get(1):1');
  cmp_ok($b->get(2),          '==',  5, 'get(2):5');
  cmp_ok($b->get(3),          '==',  1, 'get(3):1');
  cmp_ok($b->get(9),          '==',  0, 'get(9):0');
  cmp_ok($b->get(10),         '==',  0, 'get(10):0');
  cmp_ok($b->get(0xffffffff), '==', 15, 'get(0xffffffff):15');

}

###

sub test_keys {

  plan tests => 6;

  my($bag, @ref, @key);

  $bag = simple_int_bag();
  @ref = (1, 2, 3, 4, 10, 0xffffffff);

  @key = sort { $a <=> $b }  $bag->iter_keys->();
  is_deeply(\@key, \@ref, "basic key iter");
  @key = sort { $a <=> $b } keys %$bag;
  is_deeply(\@key, \@ref, "basic keys");

  $bag = simple_ip_bag();
  @ref = map { new_ip($_) }
         qw( 1.1.1.1
             2.2.2.2
             3.3.3.3
             4.4.4.4
             10.10.10.10
             255.255.255.255 );

  @key = sort $bag->iter_keys->();
  is_deeply(\@key, \@ref, "basic ip key iter");
  @key = sort keys %$bag;
  is_deeply(\@key, \@ref, "basic ip keys");

  SKIP: {
    skip("ipv6 not enabled", 2) unless SILK_IPV6_ENABLED;

    $bag = simple_ipv6_bag();
    @ref = map { new_ipv6($_) }
           qw( ::1
               ::ffff:1.1.1.1
               2::
               3::4
               5::6.7.8.9
               10:10:10:10:10:10:10:10
               ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff );

    @key = sort $bag->iter_keys->();
    is_deeply(\@key, \@ref, "basic ip key iter");
    @key = sort keys %$bag;
    is_deeply(\@key, \@ref, "basic ip keys");
  }

}

###

sub test_get {

  plan tests => 12;

  my $b;

  $b = simple_int_bag();

  cmp_ok($b->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b->get(0xfffffffe), '==', 0, 'get(0xfffffffe):0');
  cmp_ok($b->get(0xffffffff), '==', 1, 'get(0xffffffff):1');
  eval { $b->get(-1)            }; ok($@, "get(-1):error");
  eval { $b->get('foo')         }; ok($@, "get(foo):error");
  eval { $b->get('0x100000000') }; ok($@, "get(0x100000000):error");

  $b = simple_ip_bag();

  cmp_ok($b->get('0.0.0.0'),         '==', 0, 'get(0.0.0.0):0');
  cmp_ok($b->get('1.1.1.1'),         '==', 1, 'get(1.1.1.1):1');
  cmp_ok($b->get('255.255.255.254'), '==', 0, 'get(255.255.255.254):0');
  cmp_ok($b->get('255.255.255.255'), '==', 1, 'get(255.255.255.255):1');
  eval { $b->get('foo') }; ok($@, "get(foo):error");

}

###

sub test_iter {

  plan tests => 22;

  my($bag, $iter, %ref, %res, $c);

  %ref = (
    1          => 1,
    2          => 1,
    3          => 1,
    4          => 1,
    10         => 5,
    0xffffffff => 1,
  );
  $bag = simple_int_bag();
  $iter = $bag->iter();
  %res = ();
  while (my $r = $iter->()) {
    $res{$r->[0]} = $r->[1];
  }
  $c = 0;
  cmp_ok(keys %res, '==', keys %ref, "basic key count");
  while (my($k,$v) = each %ref) {
    cmp_ok($res{$k}, '==', $ref{$k}, "basic key/val match $c");
    ++$c;
  }

  %ref = (
    '1.1.1.1'         => 1,
    '2.2.2.2'         => 1,
    '3.3.3.3'         => 1,
    '4.4.4.4'         => 1,
    '10.10.10.10'     => 5,
    '255.255.255.255' => 1,
  );
  $bag  = simple_ip_bag();
  $iter = $bag->iter();
  %res = ();
  while (my $r = $iter->()) {
    $res{$r->[0]} = $r->[1];
  }
  $c = 0;
  cmp_ok(keys %res, '==', keys %ref, "basic ip key count");
  while (my($k,$v) = each %ref) {
    cmp_ok($res{$k}, '==', $ref{$k}, "basic ip key/val match $c");
    ++$c;
  }

  SKIP: {
    skip("ipv6 not enabled", 8) unless SILK_IPV6_ENABLED;

    %ref = (
      new_ip('::1')                     => 1,
      new_ip('2::')                     => 1,
      new_ip('3::4')                    => 1,
      new_ip('5::6.7.8.9')              => 1,
      new_ip('::ffff:1.1.1.1')          => 1,
      new_ip('10:10:10:10:10:10:10:10') => 5,
      new_ip('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff') => 1,
    );
    $bag = simple_ipv6_bag();
    $iter = $bag->iter();
    %res = ();
    while (my $r = $iter->()) {
      $res{$r->[0]} = $r->[1];
    }
    $c = 0;
    cmp_ok(keys %res, '==', keys %ref, "basic ipv6 key count");
    while (my($k,$v) = each %ref) {
      cmp_ok($res{$k}, '==', $ref{$k}, "basic ipv6 key/val match $c");
      ++$c;
    }
  }

}

###

sub test_sorted_iter {

  plan tests => 41;

  my($bag, @ref, @res, $c);

  @ref = (
   [ 1          => 1 ],
   [ 2          => 1 ],
   [ 3          => 1 ],
   [ 4          => 1 ],
   [ 10         => 5 ],
   [ 0xffffffff => 1 ],
  );
  $bag = simple_int_bag();
  @res = $bag->iter(1)->();
  $c = 0;
  cmp_ok(@res, '==', @ref, "basic item count");
  while ($c <= $#ref) {
    cmp_ok($res[$c][0], '==', $ref[$c][0], "basic key match $c");
    cmp_ok($res[$c][1], '==', $ref[$c][1], "basic val match $c");
    ++$c;
  }

  @ref = (
    [ '1.1.1.1'         => 1 ],
    [ '2.2.2.2'         => 1 ],
    [ '3.3.3.3'         => 1 ],
    [ '4.4.4.4'         => 1 ],
    [ '10.10.10.10'     => 5 ],
    [ '255.255.255.255' => 1 ],
  );
  $bag  = simple_ip_bag();
  @res = $bag->iter(1)->();
  $c = 0;
  cmp_ok(@res, '==', @ref, "basic ip item count");
  while ($c <= $#ref) {
    cmp_ok($res[$c][0], '==', $ref[$c][0], "basic ip key match $c");
    cmp_ok($res[$c][1], '==', $ref[$c][1], "basic ip val match $c");
    ++$c;
  }

  SKIP: {
    skip("ipv6 not enabled", 15) unless SILK_IPV6_ENABLED;

    @ref = (
      [ new_ip('::1')                     => 1 ],
      [ new_ip('::ffff:1.1.1.1')          => 1 ],
      [ new_ip('2::')                     => 1 ],
      [ new_ip('3::4')                    => 1 ],
      [ new_ip('5::6.7.8.9')              => 1 ],
      [ new_ip('10:10:10:10:10:10:10:10') => 5 ],
      [ new_ip('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff') => 1 ],
    );
    $bag = simple_ipv6_bag();
    @res = $bag->iter(1)->();
    $c = 0;
    cmp_ok(@res, '==', @ref, "basic ipv6 item count");
    while ($c <= $#ref) {
      cmp_ok($res[$c][0], '==', $ref[$c][0], "basic ipv6 key match $c");
      cmp_ok($res[$c][1], '==', $ref[$c][1], "basic ipv6 val match $c");
      ++$c;
    }
  }

}

###

sub test_values {

  plan tests => 14;

  my($bag, @ref, @res);

  @ref = sort { $a <=> $b } (1, 1, 1, 1, 5, 1);

  $bag = simple_int_bag();
  @res = sort { $a <=> $b } $bag->iter_vals->();
  cmp_ok(@res, '==', @ref, "basic value count");
  for my $c (0 .. $#ref) {
    cmp_ok($res[$c], '==', $ref[$c], "basic val match $c");
  }

  $bag = simple_ip_bag();
  @res = sort { $a <=> $b } $bag->iter_vals->();
  cmp_ok(@res, '==', @ref, "basic ip value count");
  for my $c (0 .. $#ref) {
    cmp_ok($res[$c], '==', $ref[$c], "basic ip val match $c");
  }

}

###

sub test_update {

  plan tests => 28;

  my($b1, $b2);

  $b1 = simple_int_bag();

  cmp_ok($b1->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b1->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b1->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b1->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b1->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b1->get(10),         '==', 5, 'get(10):5');
  cmp_ok($b1->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b2 = $b1->copy;
  $b2->del(3);
  $b2->set(9  => 2);
  $b2->set(10 => 2);

  $b1->update($b2);
  cmp_ok($b1->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b1->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b1->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b1->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b1->get(9),          '==', 2, 'get(9):2');
  cmp_ok($b1->get(10),         '==', 2, 'get(10):2');
  cmp_ok($b1->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b1 = simple_int_bag();

  $b1->update({ 0 => 3, 10 => 3});
  cmp_ok($b1->get(0),          '==', 3, 'get(0):3');
  cmp_ok($b1->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b1->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b1->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b1->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b1->get(10),         '==', 3, 'get(10):3');
  cmp_ok($b1->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b1 = simple_int_bag();

  $b1->update([0,0,0,0,0,0,0, 10,10,10,10,10,10,10]);
  cmp_ok($b1->get(0),          '==', 7, 'get(0):7');
  cmp_ok($b1->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b1->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b1->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b1->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b1->get(10),         '==', 7, 'get(10):7');
  cmp_ok($b1->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

}

###

sub test_incr_decr {

  plan tests => 42;

  my $b1 = simple_int_bag();

  cmp_ok($b1->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b1->get(1),          '==', 1, 'get(1):1');
  cmp_ok($b1->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b1->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b1->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b1->get(10),         '==', 5, 'get(10):5');
  cmp_ok($b1->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b1->incr(1);

  cmp_ok($b1->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b1->get(1),          '==', 2, 'get(1):2');
  cmp_ok($b1->get(2),          '==', 1, 'get(2):1');
  cmp_ok($b1->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b1->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b1->get(10),         '==', 5, 'get(10):5');
  cmp_ok($b1->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b1->decr(2);

  cmp_ok($b1->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b1->get(1),          '==', 2, 'get(1):2');
  cmp_ok($b1->get(2),          '==', 0, 'get(2):0');
  cmp_ok($b1->get(3),          '==', 1, 'get(3):1');
  cmp_ok($b1->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b1->get(10),         '==', 5, 'get(10):5');
  cmp_ok($b1->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b1->incr(3, 4);

  cmp_ok($b1->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b1->get(1),          '==', 2, 'get(1):2');
  cmp_ok($b1->get(2),          '==', 0, 'get(2):0');
  cmp_ok($b1->get(3),          '==', 5, 'get(3):5');
  cmp_ok($b1->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b1->get(10),         '==', 5, 'get(10):5');
  cmp_ok($b1->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b1->decr(10, 4);

  cmp_ok($b1->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b1->get(1),          '==', 2, 'get(1):2');
  cmp_ok($b1->get(2),          '==', 0, 'get(2):0');
  cmp_ok($b1->get(3),          '==', 5, 'get(3):5');
  cmp_ok($b1->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b1->get(10),         '==', 1, 'get(10):1');
  cmp_ok($b1->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

  $b1->incr(1, '0xffffffffffffff00');

  cmp_ok($b1->get(0),          '==', 0, 'get(0):0');
  cmp_ok($b1->get(1),          '==', string_to_uint64('0xffffffffffffff02'),
                                               'get(1):0xffffffffffffff02');
  cmp_ok($b1->get(2),          '==', 0, 'get(2):0');
  cmp_ok($b1->get(3),          '==', 5, 'get(3):5');
  cmp_ok($b1->get(9),          '==', 0, 'get(9):0');
  cmp_ok($b1->get(10),         '==', 1, 'get(10):1');
  cmp_ok($b1->get(0xffffffff), '==', 1, 'get(0xffffffff):1');

}

###

sub test_add {

  plan tests => 24;

  my($b1, $b2, $b3);

  ($b1, $b2) = simple_bags();

  $b3 = $b1 + $b2;

  cmp_ok($b3->get(1),          '==', 10, 'get(1):10');
  cmp_ok($b3->get(2),          '==', 20, 'get(2):20');
  cmp_ok($b3->get(3),          '==',  5, 'get(3):5');
  cmp_ok($b3->get(4),          '==', 10, 'get(4):10');
  cmp_ok($b3->get(5),          '==',  5, 'get(5):5');
  cmp_ok($b3->get(6),          '==', 10, 'get(6):10');
  cmp_ok($b3->get(7),          '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),          '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),          '==', 15, 'get(9):15');
  cmp_ok($b3->get(10),         '==', 15, 'get(10):15');
  cmp_ok($b3->get(11),         '==', string_to_uint64('0xfffffffffffffffe'),
                                              'get(11):0xfffffffffffffffe');
  cmp_ok($b3->get(12),         '==', string_to_uint64('0xfffffffffffffffe'),
                                              'get(12):0xfffffffffffffffe');

  $b3  = $b1->copy;
  $b3 += $b2;

  cmp_ok($b3->get(1),          '==', 10, 'get(1):10');
  cmp_ok($b3->get(2),          '==', 20, 'get(2):20');
  cmp_ok($b3->get(3),          '==',  5, 'get(3):5');
  cmp_ok($b3->get(4),          '==', 10, 'get(4):10');
  cmp_ok($b3->get(5),          '==',  5, 'get(5):5');
  cmp_ok($b3->get(6),          '==', 10, 'get(6):10');
  cmp_ok($b3->get(7),          '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),          '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),          '==', 15, 'get(9):15');
  cmp_ok($b3->get(10),         '==', 15, 'get(10):15');
  cmp_ok($b3->get(11),         '==', string_to_uint64('0xfffffffffffffffe'),
                                              'get(11):0xfffffffffffffffe');
  cmp_ok($b3->get(12),         '==', string_to_uint64('0xfffffffffffffffe'),
                                              'get(12):0xfffffffffffffffe');

}

###

sub test_subtract {

  plan tests => 24;

  my($b1, $b2, $b3);

  ($b1, $b2) = simple_bags();

  $b3 = $b1 - $b2;

  cmp_ok($b3->get(1),          '==',  0, 'get(1):0');
  cmp_ok($b3->get(2),          '==',  0, 'get(2):0');
  cmp_ok($b3->get(3),          '==',  0, 'get(3):0');
  cmp_ok($b3->get(4),          '==',  0, 'get(4):0');
  cmp_ok($b3->get(5),          '==',  5, 'get(5):5');
  cmp_ok($b3->get(6),          '==', 10, 'get(6):10');
  cmp_ok($b3->get(7),          '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),          '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),          '==',  0, 'get(9):0');
  cmp_ok($b3->get(10),         '==',  5, 'get(10):5');
  cmp_ok($b3->get(11),         '==',  0, 'get(11):0');
  cmp_ok($b3->get(12),         '==', string_to_uint64('0xfffffffffffffffc'),
                                              'get(12):0xfffffffffffffffc');

  $b3  = $b1->copy;
  $b3 -= $b2;

  cmp_ok($b3->get(1),          '==',  0, 'get(1):0');
  cmp_ok($b3->get(2),          '==',  0, 'get(2):0');
  cmp_ok($b3->get(3),          '==',  0, 'get(3):0');
  cmp_ok($b3->get(4),          '==',  0, 'get(4):0');
  cmp_ok($b3->get(5),          '==',  5, 'get(5):5');
  cmp_ok($b3->get(6),          '==', 10, 'get(6):10');
  cmp_ok($b3->get(7),          '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),          '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),          '==',  0, 'get(9):0');
  cmp_ok($b3->get(10),         '==',  5, 'get(10):5');
  cmp_ok($b3->get(11),         '==',  0, 'get(11):0');
  cmp_ok($b3->get(12),         '==', string_to_uint64('0xfffffffffffffffc'),
                                              'get(12):0xfffffffffffffffc');

}

###

sub t_cmp_g_iter {
  my($ref, $res) = @_;
  cmp_ok(@$ref, '==', @$res, "item count");
  foreach (0 .. $#$ref) {
    cmp_ok($ref->[$_][0], '==', $res->[$_][0], "item $_ 0");
    if (defined $ref->[$_][1]) {
      cmp_ok($ref->[$_][1], '==', $res->[$_][1], "item $_ 1");
    }
    else {
      ok(! defined $ref->[$_][1] && ! defined $res->[$_][1], "item $_ 1");
    }
    if (defined $ref->[$_][2]) {
      cmp_ok($ref->[$_][2], '==', $res->[$_][2], "item $_ 2");
    }
    else {
      ok(! defined $ref->[$_][2] && ! defined $res->[$_][2], "item $_ 2");
    }
  }
}

sub test_iter_group {

  plan tests => 65;

  my($b1, $b2, @ref, @res);

  @ref = (
    [1,     5,     5],
    [2,    10,    10],
    [3, undef,     5],
    [4, undef,    10],
    [5,     5, undef],
    [6,    10, undef],
    [9,     5,    10],
    [10,   10,     5],
    [11,    1, string_to_uint64('0xfffffffffffffffd')],
    [12, string_to_uint64('0xfffffffffffffffd'), 1]
  );

  ($b1, $b2) = simple_bags();

  @res = $b1->iter_group($b2)->();

  t_cmp_g_iter(\@ref, \@res);

  @ref = (
    [1, 1, undef],
    [2, 2, undef],
  );
  $b1 = new_int_bag(1 => 1,  2 => 2);
  $b2 = new_int_bag();
  @res = $b1->iter_group($b2)->();

  t_cmp_g_iter(\@ref, \@res);

  @ref = (
    [1, undef, 1],
    [2, undef, 2],
  );
  @res = $b2->iter_group($b1)->();

  t_cmp_g_iter(\@ref, \@res);

  @ref = (
    [1, 1,     4],
    [2, 2, undef],
    [3, 3, undef],
  );
  $b1 = new_int_bag(1 => 1,  2 => 2, 3 => 3);
  $b2 = new_int_bag(1 => 4);
  @res = $b1->iter_group($b2)->();

  t_cmp_g_iter(\@ref, \@res);

  @ref = (
    [1,     4, 1],
    [2, undef, 2],
    [3, undef, 3],
  );
  @res = $b2->iter_group($b1)->();

  t_cmp_g_iter(\@ref, \@res);

}

###

sub test_bag_min {

  plan tests => 12;

  my($b1, $b2, $b3);

  ($b1, $b2) = simple_bags();

  $b3 = $b1->min($b2);

  cmp_ok($b3->get(1),  '==',  5, 'get(1):5');
  cmp_ok($b3->get(2),  '==', 10, 'get(2):10');
  cmp_ok($b3->get(3),  '==',  0, 'get(3):0');
  cmp_ok($b3->get(4),  '==',  0, 'get(4):0');
  cmp_ok($b3->get(5),  '==',  0, 'get(5):0');
  cmp_ok($b3->get(6),  '==',  0, 'get(6):0');
  cmp_ok($b3->get(7),  '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),  '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),  '==',  5, 'get(9):5');
  cmp_ok($b3->get(10), '==',  5, 'get(10):5');
  cmp_ok($b3->get(11), '==',  1, 'get(11):1');
  cmp_ok($b3->get(12), '==',  1, 'get(12):1');

}

###

sub test_bag_max {

  plan tests => 12;

  my($b1, $b2, $b3);

  ($b1, $b2) = simple_bags();

  $b3 = $b1->max($b2);

  cmp_ok($b3->get(1),  '==',  5, 'get(1):5');
  cmp_ok($b3->get(2),  '==', 10, 'get(2):10');
  cmp_ok($b3->get(3),  '==',  5, 'get(3):5');
  cmp_ok($b3->get(4),  '==', 10, 'get(4):10');
  cmp_ok($b3->get(5),  '==',  5, 'get(5):5');
  cmp_ok($b3->get(6),  '==', 10, 'get(6):10');
  cmp_ok($b3->get(7),  '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),  '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),  '==', 10, 'get(9):10');
  cmp_ok($b3->get(10), '==', 10, 'get(10):10');
  cmp_ok($b3->get(11), '==', string_to_uint64('0xfffffffffffffffd'),
                                      'get(11):0xfffffffffffffffd');
  cmp_ok($b3->get(12), '==', string_to_uint64('0xfffffffffffffffd'),
                                      'get(12):0xfffffffffffffffd');

}

###

sub test_bag_div {

  plan tests => 24;

  my($b1, $b2, $b3);

  ($b1, $b2) = simple_bags();
  $b3 = $b1 / $b2;

  cmp_ok($b3->get(1),  '==',  1, 'get(1):1');
  cmp_ok($b3->get(2),  '==',  1, 'get(2):1');
  cmp_ok($b3->get(3),  '==',  0, 'get(3):0');
  cmp_ok($b3->get(4),  '==',  0, 'get(4):0');
  cmp_ok($b3->get(5),  '==',  0, 'get(5):0');
  cmp_ok($b3->get(6),  '==',  0, 'get(6):0');
  cmp_ok($b3->get(7),  '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),  '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),  '==',  1, 'get(9):1');
  cmp_ok($b3->get(10), '==',  2, 'get(10):2');
  cmp_ok($b3->get(11), '==',  0, 'get(11):0');
  cmp_ok($b3->get(12), '==', string_to_uint64('0xfffffffffffffffd'),
                                      'get(12):0xfffffffffffffffd');

  $b1->set(9 => 4);
  $b1 /= $b2;
  $b3 = $b1;

  cmp_ok($b3->get(1),  '==',  1, 'get(1):1');
  cmp_ok($b3->get(2),  '==',  1, 'get(2):1');
  cmp_ok($b3->get(3),  '==',  0, 'get(3):0');
  cmp_ok($b3->get(4),  '==',  0, 'get(4):0');
  cmp_ok($b3->get(5),  '==',  0, 'get(5):0');
  cmp_ok($b3->get(6),  '==',  0, 'get(6):0');
  cmp_ok($b3->get(7),  '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),  '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),  '==',  0, 'get(9):0');
  cmp_ok($b3->get(10), '==',  2, 'get(10):2');
  cmp_ok($b3->get(11), '==',  0, 'get(11):0');
  cmp_ok($b3->get(12), '==', string_to_uint64('0xfffffffffffffffd'),
                                      'get(12):0xfffffffffffffffd');

}

###

sub test_scalar_mul {

  plan tests => 39;

  my($b1, $b2, $b3);

  ($b1, $b2) = simple_bags();

  eval { $b3 = $b1 * 2 };
  like($@, qr/overflow|invalid|integer\s+too\s+large/i, "overflow");

  eval { $b3 = 2 * $b1 };
  like($@, qr/overflow|invalid|integer\s+too\s+large/i, "overflow");

  $b1->del(12);
  $b3 = $b1 * 2;

  cmp_ok($b3->get(1),  '==', 10, 'get(1):10');
  cmp_ok($b3->get(2),  '==', 20, 'get(2):20');
  cmp_ok($b3->get(3),  '==',  0, 'get(3):0');
  cmp_ok($b3->get(4),  '==',  0, 'get(4):0');
  cmp_ok($b3->get(5),  '==', 10, 'get(5):10');
  cmp_ok($b3->get(6),  '==', 20, 'get(6):20');
  cmp_ok($b3->get(7),  '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),  '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),  '==', 10, 'get(9):10');
  cmp_ok($b3->get(10), '==', 20, 'get(10):20');
  cmp_ok($b3->get(11), '==',  2, 'get(11):2');
  cmp_ok($b3->get(12), '==',  0, 'get(12):0');

  $b3 = 2 * $b1;

  cmp_ok($b3->get(1),  '==', 10, 'get(1):10');
  cmp_ok($b3->get(2),  '==', 20, 'get(2):20');
  cmp_ok($b3->get(3),  '==',  0, 'get(3):0');
  cmp_ok($b3->get(4),  '==',  0, 'get(4):0');
  cmp_ok($b3->get(5),  '==', 10, 'get(5):10');
  cmp_ok($b3->get(6),  '==', 20, 'get(6):20');
  cmp_ok($b3->get(7),  '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),  '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),  '==', 10, 'get(9):10');
  cmp_ok($b3->get(10), '==', 20, 'get(10):20');
  cmp_ok($b3->get(11), '==',  2, 'get(11):2');
  cmp_ok($b3->get(12), '==',  0, 'get(12):0');

  $b1 *= 2;
  $b3  = $b1;

  cmp_ok($b3->get(1),  '==', 10, 'get(1):10');
  cmp_ok($b3->get(2),  '==', 20, 'get(2):20');
  cmp_ok($b3->get(3),  '==',  0, 'get(3):0');
  cmp_ok($b3->get(4),  '==',  0, 'get(4):0');
  cmp_ok($b3->get(5),  '==', 10, 'get(5):10');
  cmp_ok($b3->get(6),  '==', 20, 'get(6):20');
  cmp_ok($b3->get(7),  '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),  '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),  '==', 10, 'get(9):10');
  cmp_ok($b3->get(10), '==', 20, 'get(10):20');
  cmp_ok($b3->get(11), '==',  2, 'get(11):2');
  cmp_ok($b3->get(12), '==',  0, 'get(12):0');

  eval { $b3 = $b1 * "d" };
  like($@, qr/non-numeric/i, "non-numeric type");
  #eval { $b3 = $b1 * new_int_bag() };
  #like($@, qr/non-numeric/i, "non-numeric type");

}

###

sub test_complement_intersect {

  plan tests => 27;

  my($b1, $b2, $b3);

  ($b1, $b2) = simple_bags();

  $b3 = $b1->complement_intersect($b2);

  cmp_ok($b3->get(1),  '==',  0, 'get(1):0');
  cmp_ok($b3->get(2),  '==',  0, 'get(2):0');
  cmp_ok($b3->get(3),  '==',  0, 'get(3):0');
  cmp_ok($b3->get(4),  '==',  0, 'get(4):0');
  cmp_ok($b3->get(5),  '==',  5, 'get(5):5');
  cmp_ok($b3->get(6),  '==', 10, 'get(6):10');
  cmp_ok($b3->get(7),  '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),  '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),  '==',  0, 'get(9):0');
  cmp_ok($b3->get(10), '==',  0, 'get(10):0');
  cmp_ok($b3->get(11), '==',  0, 'get(11):0');
  cmp_ok($b3->get(12), '==',  0, 'get(12):0');

  $b3 = $b2->complement_intersect($b1);

  cmp_ok($b3->get(1),  '==',  0, 'get(1):0');
  cmp_ok($b3->get(2),  '==',  0, 'get(2):0');
  cmp_ok($b3->get(3),  '==',  5, 'get(3):5');
  cmp_ok($b3->get(4),  '==', 10, 'get(4):10');
  cmp_ok($b3->get(5),  '==',  0, 'get(5):0');
  cmp_ok($b3->get(6),  '==',  0, 'get(6):0');
  cmp_ok($b3->get(7),  '==',  0, 'get(7):0');
  cmp_ok($b3->get(8),  '==',  0, 'get(8):0');
  cmp_ok($b3->get(9),  '==',  0, 'get(9):0');
  cmp_ok($b3->get(10), '==',  0, 'get(10):0');
  cmp_ok($b3->get(11), '==',  0, 'get(11):0');
  cmp_ok($b3->get(12), '==',  0, 'get(12):0');

  $b3 = $b1->complement_intersect([1, 2, 9, 10, 11, 12]);
  my %ref = (
    5 => 5,
    6 => 10,
  );
  my $iter = $b3->iter();
  my %res;
  while (my $r = $iter->()) {
    $res{$r->[0]} = $r->[1];
  }
  cmp_ok(keys %res, '==', keys %ref, 'item count');
  while (my($k, $v) = each %ref) {
    cmp_ok($res{$k}, '==', $ref{$k}, "item $k");
  }

}

###

sub test_ipset {

  plan tests => 18;

  my($b1, $s1, @ref, @res);

  $b1 = simple_ip_bag();
  $s1 = $b1->as_ipset();

  isa_ok($s1, SILK_IPSET_CLASS);

  @ref = map { new_ip($_) } (
    '1.1.1.1',
    '2.2.2.2',
    '3.3.3.3',
    '4.4.4.4',
    '10.10.10.10',
    '255.255.255.255',
  );
  @res = sort $s1->iter->();

  cmp_ok(@res, '==', @ref, "item count");
  foreach (0 .. $#ref) {
    cmp_ok($ref[$_], '==', $res[$_], "ip $_");
  }

  SKIP: {
    skip("ipv6 not enabled", 10) unless SILK_IPV6_ENABLED;
    $b1 = simple_ipv6_bag();
    $s1 = $b1->as_ipset();
    isa_ok($s1, SILK_IPSET_CLASS);
    @ref = map { new_ipv6($_) } (
     "::1",
     "::ffff:1.1.1.1",
     "2::",
     "3::4",
     "5::6.7.8.9",
     "10:10:10:10:10:10:10:10",
     "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff",
    );
    @res = sort $s1->iter->();
    cmp_ok(@res, '==', @ref, "item count");
    foreach (0 .. $#ref) {
      cmp_ok($res[$_], '==', $res[$_], "ipv6 $_");
    }
    $b1 = simple_int_bag();
    eval { $s1 = $b1->as_ipset() };
    like($@, qr/invalid bag key type/i, "invalid type");
  }
}

###

sub test_constrain {

  plan tests => 9;

  my($b1, %ref, %res, $iter);

  $b1 = simple_int_bag();
  $b1->add(2 => 3);
  $b1->constrain_values(2, 10);
  %ref = (
     2 => 2,
     3 => 2,
    10 => 5,
  );
  $iter = $b1->iter();
  %res = ();
  while (my $r = $iter->()) {
    $res{$r->[0]} = $r->[1];
  }
  cmp_ok(keys %res, '==', keys %ref, 'item count');
  while (my($k, $v) = each %ref) {
    cmp_ok($res{$k}, '==', $ref{$k}, "item $k");
  }

  $b1 = simple_int_bag();
  $b1->constrain_keys(2, 10);
  %ref = (
     2 => 1,
     3 => 1,
     4 => 1,
    10 => 5,
  );
  $iter = $b1->iter();
  %res = ();
  while (my $r = $iter->()) {
    $res{$r->[0]} = $r->[1];
  }
  cmp_ok(keys %res, '==', keys %ref, 'item count');
  while (my($k, $v) = each %ref) {
    cmp_ok($res{$k}, '==', $ref{$k}, "item $k");
  }
}

###

sub test_inversion {

  plan tests => 3;

  my($b1, $b2, %ref, %res, $iter);

  $b1 = simple_int_bag();
  $b2 = $b1->inversion();
  %ref = (
    1 => 5,
    5 => 1,
  );
  $iter = $b2->iter();
  %res = ();
  while (my $r = $iter->()) {
    $res{$r->[0]} = $r->[1];
  }
  cmp_ok(keys %res, '==', keys %ref, 'item count');
  while (my($k, $v) = each %ref) {
    cmp_ok($res{$k}, '==', $ref{$k}, "item $k");
  }
}

###

sub test_key_lengths {

  plan tests => 10;

  my($b1);

  $b1 = SILK_BAG_CLASS->new_integer(key_len => 1);
  $b1->set(0, 1);
  $b1->set(0xff, 1);

  eval { $b1->set(0x100, 1) };
  like($@, qr/key out of range/i, "range check");
  cmp_ok($b1->get(0xff),  '==', 1, "item 0xff ok");
  cmp_ok($b1->get(0x100), '==', 0, "item 0x100 empty");

  $b1 = SILK_BAG_CLASS->new_integer(key_len => 2);
  $b1->set(0, 1);
  $b1->set(0xff, 1);
  $b1->set(0xffff, 1);
  eval { $b1->set(0x10000, 1) };
  like($@, qr/key out of range/i, "range check");
  cmp_ok($b1->get(0xff),    '==', 1, "item 0xff ok");
  cmp_ok($b1->get(0xffff),  '==', 1, "item 0xffff ok");
  cmp_ok($b1->get(0x10000), '==', 0, "item 0x10000 empty");

  SKIP: {
    skip("ipv6 not enabled", 3) unless SILK_IPV6_ENABLED;
    $b1 = simple_ip_bag();
    $b1->set("::ffff:1.1.1.1", 1);
    eval { $b1->set("::1", 1) };
    like($@, qr/key out of range/i, "range check");
    cmp_ok($b1->get('::ffff:1.1.1.1'), '==', 1, "ipv6 item ok");
    cmp_ok($b1->get('::1'),            '==', 0, "ipv6 item empty");
  }
}

###

sub test_conversion {

  plan tests => 26;

  my($b1, %info);

  $b1 = SILK_BAG_CLASS->new_integer(key_len => 2);
  $b1->set(1, 1);
  $b1->set(0x100, 1);
  %info = $b1->get_info;

  cmp_ok($b1->get(1),     '==', 1, "get(1):1");
  cmp_ok($b1->get(0x100), '==', 1, "get(0x100):1");
  cmp_ok($info{key_len},  'eq', 2, "key_len:2");
  cmp_ok($info{key_type},  'eq', $bag_types{custom},
         "key_type:$bag_types{custom}");

  $b1->set_info(key_len => 4);
  %info = $b1->get_info;

  cmp_ok($b1->get(1),     '==', 1, "get(1):1");
  cmp_ok($b1->get(0x100), '==', 1, "get(0x100):1");
  cmp_ok($info{key_len},  'eq', 4, "key_len:4");
  cmp_ok($info{key_type},  'eq', $bag_types{custom},
         "key_type:$bag_types{custom}");

  $b1->set_info(key_len => 2);
  %info = $b1->get_info;

  cmp_ok($b1->get(1),     '==', 1, "get(1):1");
  cmp_ok($b1->get(0x100), '==', 1, "get(0x100):1");
  cmp_ok($info{key_len},  'eq', 2, "key_len:2");
  cmp_ok($info{key_type},  'eq', $bag_types{custom},
         "key_type:$bag_types{custom}");

  $b1->set_info(key_len => 1);
  %info = $b1->get_info;

  cmp_ok($b1->get(1),     '==', 1, "get(1):1");
  cmp_ok($b1->get(0x100), '==', 0, "get(0x100):0");
  cmp_ok($info{key_len},  'eq', 1, "key_len:1");
  cmp_ok($info{key_type},  'eq', $bag_types{custom},
         "key_type:$bag_types{custom}");
  eval { $b1->set(0x100, 1) };
  like($@, qr/key out of range/i, "range check");

  $b1->set_info(key_type => $bag_types{any_ipv4});
  %info = $b1->get_info;

  cmp_ok($b1->get('0.0.0.1'), '==', 1, "get(0.0.0.1):1");
  cmp_ok($b1->get('0.0.1.0'), '==', 0, "get(0.0.1.0):0");
  cmp_ok($info{key_len},      'eq', 1, "key_len:1");
  cmp_ok($info{key_type},     'eq', $bag_types{any_ipv4},
         "key_type:$bag_types{custom}");
  eval { $b1->set('0.0.1.0', 1) };
  like($@, qr/key out of range/i, "range check");

  $b1->set_info(key_len => 4);
  %info = $b1->get_info;
  $b1->set('0.0.1.0', 1);

  cmp_ok($b1->get('0.0.0.1'), '==', 1, "get(0.0.0.1):1");
  cmp_ok($b1->get('0.0.1.0'), '==', 1, "get(0.0.1.0):1");
  cmp_ok($info{key_len},      'eq', 4, "key_len:4");
  cmp_ok($info{key_type},     'eq', $bag_types{any_ipv4},
         "key_type:$bag_types{custom}");
}

###

sub test_arith_conversions {

  plan tests => 16;

  my($b1, $b2, $b3, $b4, %i1, %i2);

  $b1 = SILK_BAG_CLASS->new(
    mapping  => {1 => 2, 22 => 8, 2048 => 16},
    key_type => $bag_types{sport},
  );
  $b2 = SILK_BAG_CLASS->new(
    mapping  => {1 => 9, 53 => 3, 2048 => 5},
    key_type => $bag_types{dport},
  );
  %i1 = $b1->get_info;
  %i2 = $b2->get_info;

  cmp_ok($i1{key_type}, 'eq', $bag_types{sport}, "key_type(1):sport");
  cmp_ok($i2{key_type}, 'eq', $bag_types{dport}, "key_type(2):dport");

  $b3 = $b1 + $b2;
  $b4 = $b1 - $b2;

  cmp_ok($i1{key_type}, 'eq', $bag_types{sport}, "key_type(1):sport");
  cmp_ok($i2{key_type}, 'eq', $bag_types{dport}, "key_type(2):dport");
  cmp_ok($b3->get_info->{key_type}, 'eq', $bag_types{any_port},
         "key type 3 any_port");
  cmp_ok($b4->get_info->{key_type}, 'eq', $bag_types{any_port},
         "key type 4 any_port");
  cmp_ok($b3->cardinality, '==', 4, 'sz(3):4');
  cmp_ok($b4->cardinality, '==', 2, 'sz(4):2');

  $b3  = $b1->copy();
  $b4  = $b1->copy();
  $b3 += $b2;
  $b4 -= $b2;

  cmp_ok($b3->get_info->{key_type}, 'eq', $bag_types{any_port},
         "key_type(3):any_port");
  cmp_ok($b4->get_info->{key_type}, 'eq', $bag_types{any_port},
         "key_type(4):any_port");
  cmp_ok($b3->cardinality, '==', 4, 'sz(3):4');
  cmp_ok($b4->cardinality, '==', 2, 'sz(4):2');

  $b3  = $b2->copy();
  $b4  = $b2->copy();
  $b3 += $b1;
  $b4 -= $b1;

  cmp_ok($b3->get_info->{key_type}, 'eq', $bag_types{any_port},
         "key_type(3):any_port");
  cmp_ok($b4->get_info->{key_type}, 'eq', $bag_types{any_port},
         "key_type(4):any_port");
  cmp_ok($b3->cardinality, '==', 4, 'sz(3):4');
  cmp_ok($b4->cardinality, '==', 2, 'sz(4):2');

}

###

sub test_all {
  subtest "construction"            => \&test_construction;
  subtest "io"                      => \&test_io;
  subtest "add/get/exists"          => \&test_addget;
  subtest "copy"                    => \&test_copy;
  subtest "remove"                  => \&test_remove;
  subtest "simple get"              => \&test_simple_get;
  subtest "value type"              => \&test_val_type;
  subtest "intersect"               => \&test_intersect;
  subtest "delete"                  => \&test_delete;
  subtest "set"                     => \&test_set;
  subtest "keys"                    => \&test_keys;
  subtest "get"                     => \&test_get;
  subtest "iter"                    => \&test_iter;
  subtest "sorted iter"             => \&test_sorted_iter;
  subtest "values"                  => \&test_values;
  subtest "update"                  => \&test_update;
  subtest "incr/decr"               => \&test_incr_decr;
  subtest "add"                     => \&test_add;
  subtest "subtract"                => \&test_subtract;
  subtest "group iter"              => \&test_iter_group;
  subtest "bag min"                 => \&test_bag_min;
  subtest "bag max"                 => \&test_bag_max;
  subtest "bag div"                 => \&test_bag_div;
  subtest "scalar mul"              => \&test_scalar_mul;
  subtest "complement intersect"    => \&test_complement_intersect;
  subtest "ipset"                   => \&test_ipset;
  subtest "constrain"               => \&test_constrain;
  subtest "inversion"               => \&test_inversion;
  subtest "key lengths"             => \&test_key_lengths;
  subtest "conversion"              => \&test_conversion;
  subtest "arithmetic conversions"  => \&test_arith_conversions;
}

test_all();

###
