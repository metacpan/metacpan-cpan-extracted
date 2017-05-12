#!/usr/bin/perl -w
use strict;
my ($nt, $nt2, $nt3);

# This test checks the bug:
#    my $ID = ' ...  ';
#    %token ID = /$ID/

BEGIN { $nt = 7; }
use Test::More tests=> $nt;

# test PPCR methodology with Pascal range versus enumerated conflict
SKIP: {
  skip "t/Cplusplustokensubst.eyp not found", $nt unless ($ENV{DEVELOPER} 
                                                        && -r "t/Cplusplustokensubst.eyp" 
                                                        && -x "./eyapp");

  unlink 't/ppcr.pl';

  my $r = system(q{perl -I./lib/ eyapp -b '' -o t/ppcr.pl t/Cplusplustokensubst.eyp});
  ok(!$r, 'C++ conflict grammar with %token ID = /$ID/');

  ok(-s "t/ppcr.pl", "modulino ppcr exists");

  ok(-x "t/ppcr.pl", "modulino has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'int (x) + 2;'};

  };

  ok(!$@,'t/Cplusplustokensubst.eyp executed as modulino');

  my $expected = q{
PROG(EMPTY,EXP(TYPECAST(TERMINAL[int],ID[x]),NUM[2]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "int (x) + 2;"');

  ############################
  eval {

    $r = qx{perl -Ilib -It t/ppcr.pl -t -i -c 'int (x) = 2;'};

  };

  ok(!$@,'t/Cplusplustokensubst.eyp executed as modulino');

  $expected = q{
PROG(EMPTY,DECL(TERMINAL[int],ID[x],NUM[2]))
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "int (x) = 2;"');

  unlink 't/ppcr.pl';

}


