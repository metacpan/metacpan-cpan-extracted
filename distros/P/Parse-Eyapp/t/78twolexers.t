#!/usr/bin/perl -w
use strict;
my $nt;

BEGIN { $nt = 5 }
use Test::More tests=> 2*$nt;

SKIP: {
  skip "t/twolexers.eyp not found", $nt unless ($ENV{DEVELOPER} && -r "t/twolexers.eyp" && -x "./eyapp");

  unlink 't/twolexers.pl';

  my $r = system(q{perl -I./lib/ eyapp -TC -s -o t/twolexers.pl t/twolexers.eyp});
  
  ok(!$r, "standalone option");

  ok(-s "t/twolexers.pl", "modulino standalone exists");

  ok(-x "t/twolexers.pl", "modulino standalone has execution permits");

  local $ENV{PERL5LIB};
  my $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path
  eval {

    $r = qx{t/twolexers.pl -t -i -m 1 -c 'AA%%BB'};

  };

  ok(!$@,'t/twolexers.eyp executed as standalone modulino');

  my $expected = q{
In Lexer 1 
In Lexer 1 
In Lexer 1 
In Lexer 2 
In Lexer 2 
In Lexer 2 

s_is_first_second(
  first_is_A_first(
    TERMINAL[A],
    first_is_A(
      TERMINAL[A]
    )
  ),
  second_is_A_second(
    TERMINAL[B],
    second_is_A(
      TERMINAL[B]
    )
  )
)
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "AA%%BB"');

  unlink 't/twolexers.pl';

}

SKIP: {
  skip "t/twolexers2.eyp not found", $nt unless ($ENV{DEVELOPER} && -r "t/twolexers2.eyp" && -x "./eyapp");

  unlink 't/twolexers2.pl';

  my $r = system(q{perl -I./lib/ eyapp -TC -s -o t/twolexers2.pl t/twolexers2.eyp});
  
  ok(!$r, "standalone option");

  ok(-s "t/twolexers2.pl", "modulino standalone exists");

  ok(-x "t/twolexers2.pl", "modulino standalone has execution permits");

  local $ENV{PERL5LIB};
  my $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path
  eval {

    $r = qx{t/twolexers2.pl -t -i -m 1 -c 'A  A  %%  x1 34 '};

  };

  ok(!$@,'t/twolexers2.eyp executed as standalone modulino');

  my $expected = q{
In Lexer 2 
In Lexer 2 
In Lexer 2 

s_is_first_second(
  first_is_A_first(
    TERMINAL[A],
    first_is_A(
      TERMINAL[A]
    )
  ),
  second_is_A_second(
    TERMINAL[x1],
    second_is_A(
      TERMINAL[34]
    )
  )
)
};
  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "A  A  %%  x1 34 "');

  unlink 't/twolexers2.pl';

}
