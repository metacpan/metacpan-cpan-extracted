use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use silktest;

use Test::More tests => 15;

use Net::Silk qw( :basic );

BEGIN { use_ok( SILK_RWREC_CLASS ) }

use Net::Silk::RWRec;
use Net::Silk::TCPFlags;
use Net::Silk::Site qw( :all );

use DateTime;
use DateTime::Duration;

sub make_rwrec { new_ok(SILK_RWREC_CLASS, \@_) }

sub new_rwrec { SILK_RWREC_CLASS->new   (@_) }
sub new_ip    { SILK_IPADDR_CLASS->new  (@_) }
sub new_flags { SILK_TCPFLAGS_CLASS->new(@_) }

###

sub test_construction {

  plan tests => 2;

  my %parms = (
    application      => 1,
    bytes            => 2,
    dip              => "3.4.5.6",
    dport            => 7,
    initial_tcpflags => SILK_TCPFLAGS_CLASS->new(9),
    input            => 10,
    nhip             => "11.12.13.14",
    output           => 15,
    packets          => 16,
    protocol         => 6,
    session_tcpflags => SILK_TCPFLAGS_CLASS->new(18),
    sip              => "19.20.21.22",
    sport            => 23,
    tcpflags         => SILK_TCPFLAGS_CLASS->new(25),
    stime            => time,
    duration         => 8 * 1000,
  );
  make_rwrec(%parms);
  make_rwrec(\%parms);

}

sub test_creation_with_times {

  plan tests => 2;

  my $start = time;
  my $dur = 10 * 60 * 60;
  my $end = $start + $dur;

  my $a = new_rwrec(stime => $start, duration => $dur);
  my $b = new_rwrec(stime => $start, etime => $end);
  cmp_ok($a, '==', $b, "eq dur/stime");
  my $c = new_rwrec(stime => $start, etime => $end, duration => $dur);
  cmp_ok($a, '==', $c, "eq dur/etime/stime");

}

sub test_integer_fields {

  plan tests => 22;

  my $r = new_rwrec(
    application => 1,
    bytes       => 2,
    dport       => 3,
    input       => 4,
    output      => 5,
    packets     => 6,
    protocol    => 7,
    sport       => 8,
  );
  cmp_ok($r->application, '==', 1, 'application');
  cmp_ok($r->bytes,       '==', 2, 'bytes');
  cmp_ok($r->dport,       '==', 3, 'dport');
  cmp_ok($r->input,       '==', 4, 'input');
  cmp_ok($r->output,      '==', 5, 'output');
  cmp_ok($r->packets,     '==', 6, 'packets');
  cmp_ok($r->protocol,    '==', 7, 'protocol');
  cmp_ok($r->sport,       '==', 8, 'sport');

  eval { $r->application(-1) };
  ok($@, "fail application(-1)");
  eval { $r->bytes(-1) };
  ok($@, "fail bytes(-1)");
  eval { $r->dport(-1) };
  ok($@, "fail dport(-1)");
  eval { $r->input(-1) };
  ok($@, "fail input(-1)");
  eval { $r->output(-1) };
  ok($@, "fail output(-1)");
  eval { $r->packets(-1) };
  ok($@, "fail packets(-1)");
  eval { $r->protocol(-1) };
  ok($@, "fail protocol(-1)");
  eval { $r->sport(-1) };
  ok($@, "fail sport(-1)");

  eval { $r->application(0x10000) };
  ok($@, "fail application(0x10000)");
  # overflows to 0
  #eval { $r->bytes(0xffffffff + 1) };
  #ok($@, "fail bytes(0x100000000)");
  eval { $r->dport(0x10000) };
  ok($@, "fail dport(0x10000)");
  eval { $r->input(0x10000) };
  ok($@, "fail input(0x10000)");
  eval { $r->output(0x10000) };
  ok($@, "fail output(0x10000)");
  # overflows to 0
  #eval { $r->packets(0xffffffff + 1) };
  #ok($@, "fail packets(0x100000000)");
  eval { $r->protocol(0x100) };
  ok($@, "fail protocol(0x100)");
  eval { $r->sport(0x10000) };
  ok($@, "fail sport(0x10000)");

}

sub test_ip_fields {

  plan tests => 18;

  my $r = new_rwrec();

  $r->sip(new_ip("1.2.3.4"));
  $r->dip(new_ip("5.6.7.8"));
  $r->nhip(new_ip("9.10.11.12"));
  cmp_ok($r->sip,  '==', new_ip("1.2.3.4"),    "sip");
  cmp_ok($r->dip,  '==', new_ip("5.6.7.8"),    "dip");
  cmp_ok($r->nhip, '==', new_ip("9.10.11.12"), "nhip");
  $r->sip("1.2.3.4");
  $r->dip("5.6.7.8");
  $r->nhip("9.10.11.12");
  cmp_ok($r->sip,  '==', new_ip("1.2.3.4"),    "str sip");
  cmp_ok($r->dip,  '==', new_ip("5.6.7.8"),    "str dip");
  cmp_ok($r->nhip, '==', new_ip("9.10.11.12"), "str nhip");
  for my $bad ('0.0.0', '::x') {
    eval { $r->sip($bad) };
    ok($@, "sip bad");
    eval { $r->dip($bad) };
    ok($@, "dip bad");
    eval { $r->nhip($bad) };
    ok($@, "nhsip bad");
  }
  SKIP: {
    skip("ipv6 not enabled", 6) unless SILK_IPV6_ENABLED;
    $r->sip(new_ip("0102:0304:0506::1.2.3.4"));
    $r->dip(new_ip("0708:090a:0b0c::5.6.7.8"));
    $r->nhip(new_ip("0d0e:0f10:1112::9.10.11.12"));
    cmp_ok($r->sip,  '==', new_ip("0102:0304:0506::1.2.3.4"),    "sip");
    cmp_ok($r->dip,  '==', new_ip("0708:090a:0b0c::5.6.7.8"),    "dip");
    cmp_ok($r->nhip, '==', new_ip("0d0e:0f10:1112::9.10.11.12"), "nhip");
    $r->sip("0102:0304:0506::1.2.3.4");
    $r->dip("0708:090a:0b0c::5.6.7.8");
    $r->nhip("0d0e:0f10:1112::9.10.11.12");
    cmp_ok($r->sip,  '==', new_ip("0102:0304:0506::1.2.3.4"),    "str sip");
    cmp_ok($r->dip,  '==', new_ip("0708:090a:0b0c::5.6.7.8"),    "str dip");
    cmp_ok($r->nhip, '==', new_ip("0d0e:0f10:1112::9.10.11.12"), "str nhip");
  }

}

sub test_flags_fields {

  plan tests => 44;

  my $r = new_rwrec(protocol => 6);
  cmp_ok($r->tcpflags, '==', new_flags(''), "flags empty");
  ok(!defined $r->initial_tcpflags, "iflags undef");
  ok(!defined $r->session_tcpflags, "sflags undef");

  $r->tcpflags(new_flags('a'));
  cmp_ok($r->tcpflags, '==', new_flags('a'), "flags a");
  ok(!defined $r->initial_tcpflags, "iflags undef");
  ok(!defined $r->session_tcpflags, "sflags undef");

  $r->initial_tcpflags(new_flags('p'));
  cmp_ok($r->tcpflags, '==', new_flags('p'), "flags p");
  cmp_ok($r->initial_tcpflags, '==', new_flags('p'), "iflags p");
  cmp_ok($r->session_tcpflags, '==', new_flags(''), "sflags empty");

  $r->session_tcpflags(new_flags('u'));
  cmp_ok($r->tcpflags, '==', new_flags('pu'), "flags pu");
  cmp_ok($r->initial_tcpflags, '==', new_flags('p'), "iflags p");
  cmp_ok($r->session_tcpflags, '==', new_flags('u'), "sflags u");

  $r->tcpflags('a');
  cmp_ok($r->tcpflags, '==', new_flags('a'), "str flags a");
  ok(!defined $r->initial_tcpflags, "str iflags undef");
  ok(!defined $r->session_tcpflags, "str sflags undef");

  $r->initial_tcpflags('p');
  cmp_ok($r->tcpflags, '==', new_flags('p'), "str flags p");
  cmp_ok($r->initial_tcpflags, '==', new_flags('p'), "str iflags p");
  cmp_ok($r->session_tcpflags, '==', new_flags(''), "str sflags empty");


  $r->session_tcpflags('u');
  cmp_ok($r->tcpflags, '==', new_flags('pu'), "str flags pu");
  cmp_ok($r->initial_tcpflags, '==', new_flags('p'), "str iflags p");
  cmp_ok($r->session_tcpflags, '==', new_flags('u'), "str sflags u");

  $r->tcpflags(16);
  cmp_ok($r->tcpflags, '==', new_flags('a'), "int flags a");
  ok(!defined $r->initial_tcpflags, "int iflags undef");
  ok(!defined $r->session_tcpflags, "int sflags undef");

  $r->session_tcpflags(8);
  cmp_ok($r->tcpflags, '==', new_flags('p'), "int flags p");
  cmp_ok($r->initial_tcpflags, '==', new_flags(''),  "int iflags empty");
  cmp_ok($r->session_tcpflags, '==', new_flags('p'), "int sflags p");

  $r->initial_tcpflags(32);
  cmp_ok($r->tcpflags, '==', new_flags('pu'), "int flags pu");
  cmp_ok($r->initial_tcpflags, '==', new_flags('u'), "int iflags u");
  cmp_ok($r->session_tcpflags, '==', new_flags('p'), "int sflags p");

  $r->protocol(17);
  cmp_ok($r->tcpflags, '==', new_flags('pu'), "p17 flags pu");
  ok(!defined $r->initial_tcpflags, "p17 iflags undef");
  ok(!defined $r->session_tcpflags, "p17 sflags undef");
  eval { $r->initial_tcpflags(16) };
  ok($@, "fail p17 iflags");
  eval { $r->session_tcpflags(16) };
  ok($@, "fail p17 sflags");

  $r->protocol(6);
  for my $bad (-1, 'x', 256) {
    eval { $r->tcpflags($bad) };
    ok($@, "fail flags $bad");
    eval { $r->initial_tcpflags($bad) };
    ok($@, "fail iflags $bad");
    eval { $r->session_tcpflags($bad) };
    ok($@, "fail sflags $bad");
  }

}

sub test_site_based_fields {

  plan tests => 4;

  SKIP: {
    skip("no site config found", 4) unless HAVE_SITE_CONFIG_SILENT();
    my $r = new_rwrec();
    my $s = (sensors())[0];
    my($class, $type) = @{(classtypes())[0]};
    $r->sensor($s);
    $r->classtype($class, $type);
    cmp_ok($r->sensor, 'eq', $s, 'sensor');
    is_deeply([$r->classtype()], [$class, $type], 'classtype');
    cmp_ok($r->classname(), 'eq', $class, 'class');
    cmp_ok($r->typename(), 'eq', $type, 'type');
    #    self.assertRaises(TypeError, setattr, rec, 'sensor', 1)
    #    self.assertRaises(TypeError, setattr, rec, 'classtype', (1, 1))
    #    self.assertRaises(versionedAttributeError, setattr, rec,
    #                      'classname', 'all')
    #    self.assertRaises(versionedAttributeError, setattr, rec,
    #                      'typename', 'in')
  }
}

sub test_bit_fields {

  plan tests => 15;

  my $r = new_rwrec();
  cmp_ok($r->finnoack,        '==', 0, '0 finnoack');
  cmp_ok($r->timeout_killed,  '==', 0, '0 timeout_killed');
  cmp_ok($r->timeout_started, '==', 0, '0 timeout_started');
  $r->finnoack(1);
  cmp_ok($r->finnoack,        '==', 1, '1 finnoack');
  cmp_ok($r->timeout_killed,  '==', 0, '0 timeout_killed');
  cmp_ok($r->timeout_started, '==', 0, '0 timeout_started');
  $r->timeout_killed(1);
  cmp_ok($r->finnoack,        '==', 1, '1 finnoack');
  cmp_ok($r->timeout_killed,  '==', 1, '1 timeout_killed');
  cmp_ok($r->timeout_started, '==', 0, '0 timeout_started');
  $r->timeout_started(1);
  cmp_ok($r->finnoack,        '==', 1, '1 finnoack');
  cmp_ok($r->timeout_killed,  '==', 1, '1 timeout_killed');
  cmp_ok($r->timeout_started, '==', 1, '1 timeout_started');
  $r->finnoack(0);
  $r->timeout_killed(0);
  $r->timeout_started(0);
  cmp_ok($r->finnoack,        '==', 0, '0 finnoack');
  cmp_ok($r->timeout_killed,  '==', 0, '0 timeout_killed');
  cmp_ok($r->timeout_started, '==', 0, '0 timeout_started');

}

sub test_ipv6_conversion {

  plan tests => 14;

  SKIP: {
    skip("ipv6 not enabled", 14) unless SILK_IPV6_ENABLED;
    my $r = new_rwrec();
    ok(! $r->sip->is_ipv6(),  'sip !ipv6');
    ok(! $r->dip->is_ipv6(),  'dip !ipv6');
    ok(! $r->nhip->is_ipv6(), 'nhip !ipv6');
    $r->sip('::');
    ok($r->sip->is_ipv6(),  'sip ipv6');
    ok($r->dip->is_ipv6(),  'dip ipv6');
    ok($r->nhip->is_ipv6(), 'nhip ipv6');
    cmp_ok($r->dip,  '==', new_ip('::ffff:0000:0000'), 'dip val');
    cmp_ok($r->nhip, '==', new_ip('::ffff:0000:0000'), 'nhip val');
    $r->sip('0.0.0.0');
    ok($r->sip->is_ipv6(),  'sip ipv6');
    ok($r->dip->is_ipv6(),  'dip ipv6');
    ok($r->nhip->is_ipv6(), 'nhip ipv6');
    cmp_ok($r->sip,  '==', new_ip('::ffff:0000:0000'), 'sip val');
    cmp_ok($r->dip,  '==', new_ip('::ffff:0000:0000'), 'dip val');
    cmp_ok($r->nhip, '==', new_ip('::ffff:0000:0000'), 'nhip val');
  }

}

sub test_is_web {

  plan tests => 16;

  ok(! new_rwrec             ()->is_web(), '! is_web');
  ok(! new_rwrec(sport =>   80)->is_web(), 'sport:80 is_web');
  ok(! new_rwrec(dport =>   80)->is_web(), 'dport:80 is_web');
  ok(! new_rwrec(sport => 8080)->is_web(), 'sport:8080 is_web');
  ok(! new_rwrec(dport => 8080)->is_web(), 'dport:8080 is_web');
  ok(! new_rwrec(sport =>  443)->is_web(), 'sport:443 is_web');
  ok(! new_rwrec(dport =>  443)->is_web(), 'dport:443 is_web');

  ok(new_rwrec(protocol => 6, sport => 80)->is_web(),   'sport:6:80 is_web');
  ok(new_rwrec(protocol => 6, dport => 80)->is_web(),   'dport:6:80 is_web');
  ok(new_rwrec(protocol => 6, sport => 8080)->is_web(),
     'sport:6:8080 is_web');
  ok(new_rwrec(protocol => 6, dport => 8080)->is_web(),
     'dport:6:8080 is_web');
  ok(new_rwrec(protocol => 6, sport => 443)->is_web(), 'sport:6:443 is_web');
  ok(new_rwrec(protocol => 6, dport => 443)->is_web(), 'dport:6:443 is_web');

  my $r = new_rwrec(protocol => 6, sport => 80, dport => 80);
  ok($r->is_web(), '80:80 is_web');
  $r->sport(0);
  ok($r->is_web(), '0:80 is_web');
  $r->dport(0);
  ok(! $r->is_web(), '0:0 ! is_web');

}

sub test_is_icmp {

  plan tests => 4;

  ok(! new_rwrec()->is_icmp(), '! is_icmp');
  ok(new_rwrec(protocol => 1)->is_icmp(), 'is_icmp');
  SKIP: {
    skip("ipv6 not enabled", 2) unless SILK_IPV6_ENABLED;
    ok(! new_rwrec(protocol => 58)->is_icmp(), "ipv4:58 ! is_icmp");
    ok(new_rwrec(protocol => 58, sip => '::')->is_icmp(), "ipv6:58 is_icmp");
  }
}

sub test_equality {

  plan tests => 9;

  my $r1 = new_rwrec();
  my $r2 = new_rwrec();
  ok( ($r1 == $r2), 'r1 == r2');
  ok(!($r1 != $r2), 'r1 !!= r2');
  $r1->input(1);
  ok(!($r1 == $r2), 'r1 !== r2');
  ok( ($r1 != $r2), 'r1 != r2');
  $r2->input(1);
  ok( ($r1 == $r2), 'r1 == r2');
  ok(!($r1 != $r2), 'r1 !!= r2');

  my $r3 = $r1->copy();
  isa_ok($r3, SILK_RWREC_CLASS);
  cmp_ok($r1, '==', $r3, "copy eq");
  $r1->input(5);
  cmp_ok($r1, '!=', $r3, "copy sep");

}

sub test_as_hash {

  plan tests => 2;

  load_site();
  my $r = new_rwrec(sip => '1.1.1.1', input => 4);
  my %h = $r->as_hash();
  cmp_ok($h{sip}, '==', new_ip('1.1.1.1'), 'h{sip} = ip');
  cmp_ok($h{input}, '==', 4, 'h{input} = 4');

}

sub dt   { DateTime->new(@_) }
sub dur  { DateTime::Duration->new(@_) }

my $basis = DateTime->new(year => 1970, month => 1, day => 1);
sub deq { ! DateTime::Duration->compare(@_, $basis) }

sub test_time_fields {

  plan tests => 19;

  my($t1, $t2, $t3, $t4, $d1, $d2, $r);

  $t1 = dt(year => 2000, month => 6, day => 15);
  $t2 = dt(year => 2000, month => 6, day => 16, minute => 1);
  $d1 = dur(days => 1, minutes => 1); 
  $r = new_rwrec(stime => $t1, duration => $d1);
  cmp_ok($r->stime,    '==', $t1, 'stime');
  ok(deq($r->duration, $d1),  'duration');
  cmp_ok($r->etime,    '==', $t2, 'etime');

  $t1 = dt(year => 1970, month => 1, day => 1);
  $t2 = dt(year => 1970, month => 1, day => 1, minute => 1);
  $d1 = dur(minutes => 1);
  $r = new_rwrec(stime => $t1, duration => $d1);
  cmp_ok($r->stime,    '==', $t1, 'stime');
  ok(deq($r->duration, $d1),  'duration');
  cmp_ok($r->etime,    '==', $t2, 'etime');
  $t3 = dt(year => 1970, month => 1, day => 1, minute => 2);
  $t4 = dt(year => 1970, month => 1, day => 1, minute => 3);
  $d1 = dur(minutes => 2);
  $r->etime($t3);
  cmp_ok($r->stime,    '==', $t1, 'stime');
  ok(deq($r->duration, $d1),  'duration');
  cmp_ok($r->etime,    '==', $t3, 'etime');
  $r->stime($t2);
  cmp_ok($r->stime,    '==', $t2, 'stime');
  ok(deq($r->duration, $d1),  'duration');
  cmp_ok($r->etime,    '==', $t4, 'etime');
  $d1 = dur(minutes => 1);
  $r->duration($d1);
  cmp_ok($r->stime,    '==', $t2, 'stime');
  ok(deq($r->duration, $d1),  'duration');
  cmp_ok($r->etime,    '==', $t3, 'etime');

  $t1 = dt(year => 2038, month => 1, day => 19,
           hour => 3, minute => 14, second => 8);
  eval { $r->stime($t1) };
  ok($@, "bad future stime");
  $d1 = dur(nanoseconds => (0xffffffff + 1) * 1_000_000); # 0x100000000
  $d2 = dur(nanoseconds => 0xffffffff * 1_000_000);
  $t2 = dt(year => 2038, month => 1, day => 19,
           hour => 3, minute => 14, second => 7);
  $r->stime($t2);
  $r->duration($d2);
  # xsub overflows and receives a uint32_t with value 0
  #eval { $r->duration($d1) };
  #ok($@, "duration overflow");
  eval { $r->etime($r->stime + $d1) };
  ok($@, "etime overflow");
  cmp_ok($r->etime, '==', $r->stime + $r->duration, "etime == stime+dur");
  eval { $r->etime($r->stime + $d1) };
  ok($@, "etime overflow");

}

sub test_ip_conversion {

  plan tests => 26;

  my $r1 = new_rwrec();
  ok(! $r1->is_ipv6(), '! ipv6');
  my $r2 = $r1->to_ipv4();
  ok(! $r2->is_ipv6(), '! ipv6');
  cmp_ok($r2->sip,  '==', new_ip('0.0.0.0'), 'sip 0.0.0.0');
  cmp_ok($r2->dip,  '==', new_ip('0.0.0.0'), 'dip 0.0.0.0');
  cmp_ok($r2->nhip, '==', new_ip('0.0.0.0'), 'nhip 0.0.0.0');
  SKIP: {
    skip("ipv6 not enabled", 21) unless SILK_IPV6_ENABLED;
    my $r3 = $r1->to_ipv6();
    ok(! $r1->is_ipv6(), '! ipv6');
    ok(  $r3->is_ipv6(), 'ipv6');
    cmp_ok($r3->sip,  '==', new_ip('::ffff:0.0.0.0'), 'sip ::ffff:0.0.0.0');
    cmp_ok($r3->dip,  '==', new_ip('::ffff:0.0.0.0'), 'dip ::ffff:0.0.0.0');
    cmp_ok($r3->nhip, '==', new_ip('::ffff:0.0.0.0'), 'nhip ::ffff:0.0.0.0');
    my $r4 = $r3->to_ipv4();
    my $r5 = $r3->to_ipv6();
    ok(! $r1->is_ipv6(), '! ipv6');
    ok(! $r2->is_ipv6(), '! ipv6');
    ok(  $r3->is_ipv6(), 'ipv6');
    ok(! $r4->is_ipv6(), '! ipv6');
    ok(  $r5->is_ipv6(), 'ipv6');
    cmp_ok($r4->sip,  '==', new_ip('0.0.0.0'), 'sip 0.0.0.0');
    cmp_ok($r4->dip,  '==', new_ip('0.0.0.0'), 'dip 0.0.0.0');
    cmp_ok($r4->nhip, '==', new_ip('0.0.0.0'), 'nhip 0.0.0.0');
    cmp_ok($r5->sip,  '==', new_ip('::ffff:0.0.0.0'), 'sip ::ffff:0.0.0.0');
    cmp_ok($r5->dip,  '==', new_ip('::ffff:0.0.0.0'), 'dip ::ffff:0.0.0.0');
    cmp_ok($r5->nhip, '==', new_ip('::ffff:0.0.0.0'), 'nhip ::ffff:0.0.0.0');
    $r1->sip('::');
    ok(  $r1->is_ipv6(), 'ipv6');
    cmp_ok($r1->sip,  '==', new_ip('::'), 'sip ::');
    my $r6 = $r1->to_ipv4();
    ok(  $r1->is_ipv6(), 'ipv6');
    cmp_ok($r1->sip,  '==', new_ip('::'), 'sip ::');
    ok(! defined $r6, "no conversion");
  }

}

###

sub test_all {

  subtest "construction"        => \&test_construction;
  subtest "creation_with_times" => \&test_creation_with_times;
  subtest "integer_fields"      => \&test_integer_fields;
  subtest "ip_fields"           => \&test_ip_fields;
  subtest "flags_fields"        => \&test_flags_fields;
  subtest "site_based_fields"   => \&test_site_based_fields;
  subtest "bit_fields"          => \&test_bit_fields;
  subtest "ipv6_conversion"     => \&test_ipv6_conversion;
  subtest "is_web"              => \&test_is_web;
  subtest "is_icmp"             => \&test_is_icmp;
  subtest "equality"            => \&test_equality;
  subtest "as_hash"             => \&test_as_hash;
  subtest "time_fields"         => \&test_time_fields;
  subtest "ip_conversion"       => \&test_ip_conversion;

}

test_all();

###
