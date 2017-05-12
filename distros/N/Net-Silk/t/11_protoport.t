use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use silktest;

use Test::More tests => 2;

use Net::Silk qw( :basic );

BEGIN { use_ok( SILK_PROTOPORT_CLASS ) }

sub make_pp { SILK_PROTOPORT_CLASS->new(@_) }

sub test_construction {

  plan tests => 139;

  my $pp;

  for my $proto (0, 6, 255) {
    for my $port (0, 80, 443, 65535) {
      $pp = new_ok(SILK_PROTOPORT_CLASS, [$proto, $port]);
      cmp_ok($pp->proto, '==', $proto,  "protocol $proto");
      cmp_ok($pp->port,  '==', $port, "port $port");
      $pp = new_ok(SILK_PROTOPORT_CLASS, [[$proto, $port]]);
      cmp_ok($pp->proto, '==', $proto,  "protocol $proto");
      cmp_ok($pp->port,  '==', $port, "port $port");
      $pp = new_ok(SILK_PROTOPORT_CLASS, ["$proto:$port"]);
      cmp_ok($pp->proto, '==', $proto,  "protocol $proto");
      cmp_ok($pp->port,  '==', $port, "port $port");

      cmp_ok("$pp", 'eq', "$proto:$port", "string $proto:$port");
    }
  }

  $pp = new_ok(SILK_PROTOPORT_CLASS, [0x60050]);
  cmp_ok($pp->proto, '==', 6,  "protocol 6");
  cmp_ok($pp->port,  '==', 80, "port 80");

  my $pp2 = new_ok(SILK_PROTOPORT_CLASS, [8, 100]);
  ok($pp  != $pp2, "pp ne");
  ok($pp  <  $pp2, "pp lt");
  ok($pp2 >  $pp,  "pp lt");

  eval { make_pp(-1, 80) }; 
  ok($@ =~ /invalid protocol/, "(-1, 80) invalid protocol");
  eval { make_pp([-1, 80]) }; 
  ok($@ =~ /invalid protocol/, "[-1, 80] invalid protocol");
  eval { make_pp("-1:80") }; 
  ok($@ =~ /invalid proto\/port/, "-1:80 invalid protocol");
  eval { make_pp(256, 80) }; 
  ok($@ =~ /invalid protocol/, "(256, 80) invalid protocol");
  eval { make_pp([256, 80]) }; 
  ok($@ =~ /invalid protocol/, "[256, 80] invalid protocol");
  eval { make_pp("256:80") }; 
  ok($@ =~ /invalid protocol/, "256:80 invalid protocol");

  eval { make_pp(6, -1) }; 
  ok($@ =~ /invalid port/, "(6, -1) invalid port");
  eval { make_pp([6, -1]) }; 
  ok($@ =~ /invalid port/, "[6, -1] invalid port");
  eval { make_pp("6:-1") }; 
  ok($@ =~ /invalid proto\/port/, "6:-1 invalid port");
  eval { make_pp(6, 65536) }; 
  ok($@ =~ /invalid port/, "(6, 65536) invalid port");
  eval { make_pp([6, 65536]) }; 
  ok($@ =~ /invalid port/, "[6, 65536] invalid port");
  eval { make_pp("6:65536") }; 
  ok($@ =~ /invalid port/, "6:65536 invalid port");

}

sub test_all {
  subtest "construction" => \&test_construction;
}

test_all();
