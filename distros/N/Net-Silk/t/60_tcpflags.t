use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use silktest;

use Test::More tests => 9;

use Math::BigInt;

use Net::Silk qw( :basic );

BEGIN { use_ok( SILK_TCPFLAGS_CLASS ) }

use Net::Silk::TCPFlags qw( :flags );

sub make_flags { new_ok(SILK_TCPFLAGS_CLASS, \@_) }

sub new_flags { SILK_TCPFLAGS_CLASS->new(@_) }

sub fail_make_flags   {
  eval { SILK_TCPFLAGS_CLASS->new(@_) };
  ok($@, "fail new tcpflags");
}

###

sub test_construction {

  plan tests => 282;

  for my $n (0 .. 255) {
    make_flags($n);
  }
  make_flags('F');
  make_flags('S');
  make_flags('R');
  make_flags('P');
  make_flags('U');
  make_flags('E');
  make_flags('C');
  make_flags('  A  ');
  make_flags('FSRPUECA');
  make_flags('f');
  make_flags('s');
  make_flags('r');
  make_flags('p');
  make_flags('u');
  make_flags('e');
  make_flags('c');
  make_flags('  a  ');
  make_flags('fsrpueca');
  make_flags('aa');
  make_flags('');
  make_flags(new_flags(0));
  make_flags(new_flags(''));

  fail_make_flags(-1);
  fail_make_flags(256);
  fail_make_flags('x');
  fail_make_flags('fsrpuecax');

}

###

sub test_string {
  
  plan tests => 12;
  
  my $f;
  $f = new_flags('FSRPAUEC');
  cmp_ok("$f", 'eq', 'FSRPAUEC', "quote eq");
  cmp_ok( $f,  'eq', 'FSRPAUEC', "unquote eq");
  cmp_ok($f->padded(), 'eq', 'FSRPAUEC', "padded eq");
  $f = new_flags('F');
  cmp_ok("$f", 'eq', 'F', "quote eq");
  cmp_ok( $f,  'eq', 'F', "unquote eq");
  cmp_ok($f->padded(), 'eq', 'F       ', "padded eq");
  $f = new_flags('C');
  cmp_ok("$f", 'eq', 'C', "quote eq");
  cmp_ok( $f,  'eq', 'C', "unquote eq");
  cmp_ok($f->padded(), 'eq', '       C', "padded eq");
  $f = new_flags('FSRAUEC');
  cmp_ok("$f", 'eq', 'FSRAUEC', "quote eq");
  cmp_ok( $f,  'eq', 'FSRAUEC', "unquote eq");
  cmp_ok($f->padded(), 'eq', 'FSR AUEC', "padded eq");

}

sub test_members {

  plan tests => 16,

  my $f;
  $f = new_flags('fsrpueca');
  ok($f->fin, "fin");
  ok($f->syn, "syn");
  ok($f->rst, "rst");
  ok($f->psh, "psh");
  ok($f->ack, "ack");
  ok($f->urg, "urg");
  ok($f->ece, "ece");
  ok($f->cwr, "cwr");
  $f = new_flags('');
  ok(! $f->fin, "!fin");
  ok(! $f->syn, "!syn");
  ok(! $f->rst, "!rst");
  ok(! $f->psh, "!psh");
  ok(! $f->ack, "!ack");
  ok(! $f->urg, "!urg");
  ok(! $f->ece, "!ece");
  ok(! $f->cwr, "!cwr");

}

sub test_constants {

  plan tests => 8;

  cmp_ok(new_flags('f'), '==', TCP_FIN, "TCP_FIN");
  cmp_ok(new_flags('s'), '==', TCP_SYN, "TCP_SYN");
  cmp_ok(new_flags('r'), '==', TCP_RST, "TCP_RST");
  cmp_ok(new_flags('p'), '==', TCP_PSH, "TCP_PSH");
  cmp_ok(new_flags('a'), '==', TCP_ACK, "TCP_ACK");
  cmp_ok(new_flags('u'), '==', TCP_URG, "TCP_URG");
  cmp_ok(new_flags('e'), '==', TCP_ECE, "TCP_ECE");
  cmp_ok(new_flags('c'), '==', TCP_CWR, "TCP_CWR");

}

sub test_int_conv {

  plan tests => 16;

  cmp_ok(int(TCP_FIN), '==',   1, 'int(TCP_FIN) == 1');
  cmp_ok(int(TCP_SYN), '==',   2, 'int(TCP_SYN) == 2');
  cmp_ok(int(TCP_RST), '==',   4, 'int(TCP_RST) == 4');
  cmp_ok(int(TCP_PSH), '==',   8, 'int(TCP_PSH) == 8');
  cmp_ok(int(TCP_ACK), '==',  16, 'int(TCP_ACK) == 16');
  cmp_ok(int(TCP_URG), '==',  32, 'int(TCP_URG) == 32');
  cmp_ok(int(TCP_ECE), '==',  64, 'int(TCP_ECE) == 64');
  cmp_ok(int(TCP_CWR), '==', 128, 'int(TCP_CWR) == 128');

  cmp_ok(TCP_FIN, '==',   1, 'TCP_FIN == 1');
  cmp_ok(TCP_SYN, '==',   2, 'TCP_SYN == 2');
  cmp_ok(TCP_RST, '==',   4, 'TCP_RST == 4');
  cmp_ok(TCP_PSH, '==',   8, 'TCP_PSH == 8');
  cmp_ok(TCP_ACK, '==',  16, 'TCP_ACK == 16');
  cmp_ok(TCP_URG, '==',  32, 'TCP_URG == 32');
  cmp_ok(TCP_ECE, '==',  64, 'TCP_ECE == 64');
  cmp_ok(TCP_CWR, '==', 128, 'TCP_CWR == 128');

}

sub test_inequality {

  plan tests => 4;

  my $f = new_flags('f');

  cmp_ok($f, '==', new_flags('F'),  "f == F");
  cmp_ok($f, '!=', new_flags('FA'), "f != FA");
  cmp_ok($f, 'eq', new_flags('F'),  "f eq F");
  cmp_ok($f, 'ne', new_flags('FA'), "f ne FA");

}

sub test_binary {

  plan tests => 6;

  cmp_ok(~ new_flags('fsrp'), '==', new_flags('ueca'), "~fsrp == ueca");
  cmp_ok(new_flags('fsrp') & new_flags('fpua'), '==',
         new_flags('fp'), "fsrp & fpua == fp");
  cmp_ok(new_flags('frp') | new_flags('fa'), '==',
         new_flags('frpa'), "frp | fa == frpa");
  cmp_ok(new_flags('frp') ^ new_flags('fa'), '==',
         new_flags('rpa'), "frp ^ fa == rpa");
  ok(  new_flags('a'), "exist a");
  ok(! new_flags(''),  "exist !");
}

sub test_matches {

  plan tests => 6;

  ok(  new_flags('fsrp')->matches('fs/fsau'),  "fsrp match fs/fsau");
  ok(!(new_flags('fsrp')->matches('fs/fspu')), "fsrp !match fs/fspu");
  ok(  new_flags('fs')  ->matches('fs'),       "fs match fs");
  ok(  new_flags('fsa') ->matches('fs'),       "fsa match fs");
  eval { new_flags('')->matches('a/s/') };
  ok($@, "ok invalid match str");
  eval { new_flags('')->matches('x') };
  ok($@, "ok invalid match str");

}

###

sub test_all {

  subtest "construction" => \&test_construction;
  subtest "string"       => \&test_string;
  subtest "members"      => \&test_members;
  subtest "constants"    => \&test_constants;
  subtest "int_conv"     => \&test_int_conv;
  subtest "inequality"   => \&test_inequality;
  subtest "binary"       => \&test_binary;
  subtest "matches"      => \&test_matches;

}

test_all();

###
