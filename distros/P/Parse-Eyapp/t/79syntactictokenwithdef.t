#!/usr/bin/perl -w
use strict;
my $nt;

BEGIN { $nt = 4 }
use Test::More tests=> 2*$nt+2;

SKIP: {
  skip "t/SemanticInfoInTokens.eyp not found", $nt unless ($ENV{DEVELOPER} && -r "t/SemanticInfoInTokens.eyp" && -x "./eyapp");

  unlink 't/SemanticInfoInTokens.pl';

  my $r = system(q{perl -I./lib/ eyapp -b '' -o t/SemanticInfoInTokens.pl t/SemanticInfoInTokens.eyp 2> t/err});
  
  ok(!$r, "compiled t/SemanticInfoInTokens.eyp with eyapp");

  ok(-s "t/SemanticInfoInTokens.pl", "modulino SemanticInfoInTokens.pl exists");

  ok(-x "t/SemanticInfoInTokens.pl", "modulino SemanticInfoInTokens.pl has execution permits");

  ok((-s 't/err' == 0), 'No warnings during compilation of t/SemanticInfoInTokens.eyp');

  unlink 't/SemanticInfoInTokens.pl';
  unlink 't/err';

}

SKIP: {
  skip "t/syntactictoken.eyp not found", $nt+2 unless ($ENV{DEVELOPER} && -r "t/syntactictoken.eyp" && -x "./eyapp");

  unlink 't/syntactictoken.pl';

  my $r = system(q{perl -I./lib/ eyapp -TC -o t/syntactictoken.pl t/syntactictoken.eyp 2> t/err});
  
  ok(!$r, "compiled t/syntactictoken.eyp with eyapp");

  ok(-s "t/syntactictoken.pl", "modulino syntactictoken.pl exists");

  ok(-x "t/syntactictoken.pl", "modulino syntactictoken.pl has execution permits");

  ok((-s 't/err' == 0), 'No warnings during compilation of t/syntactictoken.eyp');

  eval {

    $r = qx{t/syntactictoken.pl -t -i -m 1 -c '4 2 a'};

  };

  ok(!$@,'t/syntactictoken.pl executed as modulino');

  my $expected = q{
s_is_s_W(
  s_is_s_N(
    s_is_N(
      TERMINAL[4]
    ),
    TERMINAL[2]
  ),
  TERMINAL[a]
)
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "4 2 a"');

  unlink 't/syntactictoken.pl';
  unlink 't/err';

}
