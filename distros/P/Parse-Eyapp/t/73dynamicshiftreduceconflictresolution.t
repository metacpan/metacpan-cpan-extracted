#!/usr/bin/perl -w
use strict;
my $nt;

BEGIN { $nt = 9 }
use Test::More tests=>$nt;
#use_ok qw(Parse::Eyapp) or exit;

SKIP: {
  skip "t/dynamicresolution/DynamicallyChangingTheParser.eyp not found", $nt unless ($ENV{DEVELOPER} && -r "t/dynamicresolution/DynamicallyChangingTheParser.eyp" && -x "./eyapp");

  unlink 't/Calc.pm';

  my $r = system(q{perl -I./lib/ eyapp -b '' -s -o t/dynamicresolution/persvd.pl t/dynamicresolution/DynamicallyChangingTheParser.eyp});
  
  ok(!$r, "standalone option");

  ok(-s "t/dynamicresolution/persvd.pl", "modulino standalone exists");

  ok(-x "t/dynamicresolution/persvd.pl", "modulino standalone has execution permits");

  local $ENV{PERL5LIB};
  my $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path
  eval {

    $r = qx{t/dynamicresolution/persvd.pl -t -c '{D; S} {D; D; S}'};

  };

  ok(!$@,'DynamicallyChangingTheParser executed as standalone modulino');

  my $expected = qr{PROG\(BLOCK_DS\(D1,S1\),BLOCK_DS\(D2\(TERMINAL,D1\),S1\)\)};

  like($r, $expected,'AST for {D; S} {D; D; S}');

  eval {
    $r = qx{t/dynamicresolution/persvd.pl -t -c '{D; S} {S}'};
  };

  ok(!$@,'DynamicallyChangingTheParser executed as standalone modulino');

  $expected = qr{PROG\(BLOCK_DS\(D1,S1\),BLOCK_S\)};

  like($r, $expected,'AST for {D; S} {S}');

  eval {
    $r = qx{t/dynamicresolution/persvd.pl -t -c '{D;S}'};
  };

  ok(!$@,'DynamicallyChangingTheParser executed as standalone modulino');

  $expected = qr{PROG\(BLOCK_DS\(D1,S1\)\)};

  like($r, $expected,'AST for {D;S}');

  unlink 't/dynamicresolution/persvd.pl';

}

