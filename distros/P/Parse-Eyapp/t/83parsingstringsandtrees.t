#!/usr/bin/perl -w
use strict;
my ($nt, $nt2);

BEGIN { 
$nt = 21; 
}
use Test::More tests=>$nt;

SKIP: {
  skip "t/ParsingStringsAndTrees/Infix.eyp not found", $nt 
     unless ($ENV{DEVELOPER} 
            && ($ENV{DEVELOPER} eq 'casiano') 
            && -r "t/ParsingStringsAndTrees/Infix.eyp" 
            && -r "t/ParsingStringsAndTrees/I2PIR.trg" 
            && -r "t/ParsingStringsandTrees/input1.inf" 
            && -x "./eyapp");

  unlink 't/ParsingStringsAndTrees/Infix.pm';
  unlink 't/ParsingStringsAndTrees/I2PIR.pm';
  unlink 't/ParsingStringsAndTrees/input1.pir';

  my $r = system(q{perl -I./lib/ eyapp t/ParsingStringsAndTrees/Infix.eyp});
  
  ok(!$r, "Infix.eyp compiled");

  ok(-s "t/ParsingStringsAndTrees/Infix.pm", "module Infix.pm exists");

  $r = system(q{perl -I./lib/ treereg -m main t/ParsingStringsAndTrees/I2PIR.trg});
  
  ok(!$r, "I2PIR.trg compiled");

  ok(-s "t/ParsingStringsAndTrees/I2PIR.pm", "module I2PIR.pm exists");

  ##################### compile input1.inf 
  eval {
    $r = qx{perl -Ilib -I t/ParsingStringsAndTrees/ t/ParsingStringsAndTrees/infix2pir.pl t/ParsingStringsandTrees/input1.inf 2>&1};
  };

  ok(!$@,'infix2pir.pl compiled input1.inf');

  my $expected =  q{
.sub 'main' :main
    .local num a, b, c, d
    b = 5
    a = b + 2
    
    a = 0
    print "a = "
    print a
    print "\n"
    
    a = a + 1
    
    $N5 = a * 4
    d = $N5 - b
    
    $N7 = a * b
    c = $N7 + d
    
    print "c = "
    print c
    print "\n"
    
    print "d = "
    print d
    print "\n"

.end

  };
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;

  like($r, $expected,'Parrot code for input1');

  ##################### compile simple.inf 
  eval {
    $r = qx{perl -Ilib -I t/ParsingStringsAndTrees/ t/ParsingStringsAndTrees/infix2pir.pl t/ParsingStringsandTrees/simple.inf 2>&1};
  };

  ok(!$@,'infix2pir.pl compiles simple.inf');

  $expected =  q{
.sub 'main' :main
    .local num a, b
    b = 1
    $N1 = b * 2
    a = 5 - $N1

.end

  };
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;

  like($r, $expected,'Parrot code for simple');

  ##################### compile simple2.inf 
  eval {
    $r = qx{perl -Ilib -I t/ParsingStringsAndTrees/ t/ParsingStringsAndTrees/infix2pir.pl t/ParsingStringsandTrees/simple2.inf 2>&1};
  };

  ok(!$@,'infix2pir.pl compiles simple2.inf');

  $expected =  q{
.sub 'main' :main
    .local num a, b
    b = 1
    $N1 = b * 2
    a = 5 - $N1
    
    print "a = "
    print a
    print "\n"
    
    print "b = "
    print b
    print "\n"

.end

  };
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;

  like($r, $expected,'Parrot code for simple2');

  ##################### compile simple3.inf 
  eval {
    $r = qx{perl -Ilib -I t/ParsingStringsAndTrees/ t/ParsingStringsAndTrees/infix2pir.pl t/ParsingStringsandTrees/simple3.inf 2>&1};
  };

  ok(!$@,'infix2pir.pl compiles simple3.inf');

  $expected =  q{
.sub 'main' :main
    .local num a
    $N1 = a + 1
    $N2 = 2 * $N1
.end

  };
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;

  like($r, $expected,'Parrot code for simple3');

  ##################### compile fold.inf 
  eval {
    $r = qx{perl -Ilib -I t/ParsingStringsAndTrees/ t/ParsingStringsAndTrees/infix2pir.pl t/ParsingStringsandTrees/fold.inf 2>&1};
  };

  ok(!$@,'infix2pir.pl compiles fold.inf');

  $expected =  q{
.sub 'main' :main
    .local num a
    a = 0
.end

  };
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;

  like($r, $expected,'Parrot code for fold');

  ##################### compile simple4.inf 
  eval {
    $r = qx{perl -Ilib -I t/ParsingStringsAndTrees/ t/ParsingStringsAndTrees/infix2pir.pl t/ParsingStringsandTrees/simple4.inf 2>&1};
  };

  ok(!$@,'infix2pir.pl compiles simple4.inf');

  $expected =  q{
.sub 'main' :main
    .local num a
    $N1 = a + 1
    $N2 = 2 * $N1
.end

  };
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;

  like($r, $expected,'Parrot code for simple4');

  like($r, $expected,'Parrot code for fold');

  ##################### compile simple5.inf 
  eval {
    $r = qx{perl -Ilib -I t/ParsingStringsAndTrees/ t/ParsingStringsAndTrees/infix2pir.pl t/ParsingStringsandTrees/simple5.inf 2>&1};
  };

  ok(!$@,'infix2pir.pl compiles simple5.inf');

  $expected =  q{
.sub 'main' :main
    .local num a
    $N1 = - a
    $N2 = $N1 * 2
.end

  };
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;

  like($r, $expected,'Parrot code for simple5');

  ##################### compile simple6.inf 
  eval {
    $r = qx{perl -Ilib -I t/ParsingStringsAndTrees/ t/ParsingStringsAndTrees/infix2pir.pl t/ParsingStringsandTrees/simple6.inf 2>&1};
  };

  ok(!$@,'infix2pir.pl compiles simple6.inf');

  $expected =  q{
.sub 'main' :main
    .local num a, b
    $N1 = b * 2
    a = 5 - $N1

.end

  };
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;

  like($r, $expected,'Parrot code for simple6');

  unlink 't/ParsingStringsAndTrees/Infix.pm';
  unlink 't/ParsingStringsAndTrees/I2PIR.pm';
}

