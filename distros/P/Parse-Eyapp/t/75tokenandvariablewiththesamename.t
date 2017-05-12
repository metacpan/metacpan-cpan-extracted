#!/usr/bin/perl -w
use strict;
my $nt;

BEGIN { $nt = 5 }
use Test::More tests=>$nt;

SKIP: {
  skip "t/pascalenumeratedvsrangesolvedviadyn_bug.eyp not found", $nt unless ($ENV{DEVELOPER} && -r "t/pascalenumeratedvsrangesolvedviadyn_bug.eyp" && -x "./eyapp");

  unlink 't/pascal.pl';

  my $r = system(q{perl -I./lib/ eyapp -T -b '' -s -o t/pascal.pl t/pascalenumeratedvsrangesolvedviadyn_bug.eyp});
  
  ok(!$r, "standalone option");

  ok(-s "t/pascal.pl", "modulino standalone exists");

  ok(-x "t/pascal.pl", "modulino standalone has execution permits");

  local $ENV{PERL5LIB};
  my $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path
  eval {

    $r = qx{t/pascal.pl -t -i -c 'type r = (x+2)*3 ..  y/2 ;'};

  };

  ok(!$@,'t/pascalenumeratedvsrangesolvedviadyn_bug.eyp executed as standalone modulino');

  my $expected = q{
typeDecl_is_type_ID_type(
    TERMINAL[r],
    RANGE(
      TIMES(PLUS(ID(TERMINAL[x]),NUM(TERMINAL[2])),NUM(TERMINAL[3])),
      DIV(ID(TERMINAL[y]),NUM(TERMINAL[2]))))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "type r = (x+2)*3 ..  y/2 ;"');

  unlink 't/pascal.pl';

}

