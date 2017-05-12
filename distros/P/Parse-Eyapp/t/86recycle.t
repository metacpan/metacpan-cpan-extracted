#!/usr/bin/perl -w
use strict;
my ($nt, $nt2, $nt3, $nt4, $nt5, $nt6);

BEGIN { $nt = 4; $nt2 = 4; 
}
use Test::More tests=> $nt+$nt2;

# test grammar recycling
SKIP: {
  skip "t/PostfixWithActions.eyp not found", $nt unless ($ENV{DEVELOPER} 
                                                        && -r "t/PostfixWithActions.eyp" 
                                                        && -r "t/rewritepostfixwithactions.pl" 
                                                        && -x "./eyapp");

  unlink 't/PostfixWithActions.pm';

  my $r = system(q{perl -I./lib/ eyapp  t/PostfixWithActions.eyp 2>&1});
  ok(!$r, "PostfixWithActions.eyp compiled");

  ok(-s "t/PostfixWithActions.pm", "module PostfixWithActions.pm exists");

  eval {

    $r = qx{perl -Ilib -It t/rewritepostfixwithactions.pl 'a = 2+3'};

  };

  ok(!$@,'t/rewritepostfixwithactions.pl executed');

  my $expected = q{
    2 3 PLUS &a ASSIGN
    5
    ASSIGN(TERMINAL[a],PLUS(NUM(TERMINAL[2]),NUM(TERMINAL[3])))
  };

  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'3 semantics for " a = 2+3"');

  unlink 't/PostfixWithActions.pm';
}

SKIP: {
  skip "t/NoacInh.eyp not found", $nt2 unless ($ENV{DEVELOPER} 
                                                        && -r "t/NoacInh.eyp" 
                                                        && -r "t/icalcu_and_ipost.pl" 
                                                        && -x "./eyapp");

  unlink 't/NoacInh.pm';

  my $r = system(q{perl -I./lib/ eyapp  t/NoacInh.eyp 2>&1});
  ok(!$r, "NoacInh.eyp compiled");

  ok(-s "t/NoacInh.pm", "module NoacInh.pm exists");

  eval {

    $r = qx{perl -Ilib -It t/icalcu_and_ipost.pl '2*(4+3)'};

  };

  ok(!$@,'t/icalcu_and_ipost.pl executed');

  my $expected = q{
    14
    2 4 3 + 
  };

  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'2 diffrent semenatics for "2*(4+3)"');

  unlink 't/NoacInh.pm';
}


