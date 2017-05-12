#!/usr/bin/perl -w
use strict;
my ($nt, $nt2, $nt3, $nt4, $nt5, $nt6);

BEGIN { $nt = 5; $nt2 = 5; 
}
use Test::More tests=> $nt+$nt2;

# test default naming scheme
SKIP: {
  skip "t/default_naming_scheme.eyp not found", $nt unless ($ENV{DEVELOPER} 
                                                        && -r "t/default_naming_scheme.eyp" 
                                                        && -x "./eyapp");

  unlink 't/default_naming_scheme.pm';

  my $r = system(q{perl -I./lib/ eyapp  -C t/default_naming_scheme.eyp 2>&1});
  ok(!$r, "default_naming_scheme.eyp compiled");

  ok(-s "t/default_naming_scheme.pm", "module default_naming_scheme.pm exists");

  ok(-x "t/default_naming_scheme.pm", "modulino default_naming_scheme.pm has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/default_naming_scheme.pm -t -i -c '*a = b'};

  };

  ok(!$@,'t/default_naming_scheme.pm executed');

  my $expected = q{
     s_1(l_3(TERMINAL,r_5(l_4(TERMINAL[a]))),TERMINAL,r_5(l_4(TERMINAL[b])))
  };

  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,'AST for "*a = b" as expected under default naming scheme');

  unlink 't/default_naming_scheme.pm';
}

SKIP: {
  skip "t/GiveNamesToCalc.eyp not found", $nt2 unless ($ENV{DEVELOPER} 
                                                        && -r "t/GiveNamesToCalc.eyp" 
                                                        && -x "./eyapp");

  unlink 't/GiveNamesToCalc.pm';

  my $r = system(q{perl -I./lib/ eyapp  -C t/GiveNamesToCalc.eyp 2>&1});
  ok(!$r, "GiveNamesToCalc.eyp compiled");

  ok(-s "t/GiveNamesToCalc.pm", "module GiveNamesToCalc.pm exists");

  ok(-x "t/GiveNamesToCalc.pm", "modulino GiveNamesToCalc.pm has execution permits");

  eval {

    $r = qx{perl -Ilib -It t/GiveNamesToCalc.pm -t -i -c 'a = 2*3'};

  };

  ok(!$@,'t/GiveNamesToCalc.pm executed');

  my $expected = q{
     line_is_exp(var_is_VAR[a],exp_is_TIMES(exp_is_NUM[2],exp_is_NUM[3]))
  };

  $expected =~ s/\s+//g;
  $expected = quotemeta($expected);
  $expected = qr{$expected};

  $r =~ s/\s+//g;


  like($r, $expected,q{AST for "a = 2*3" as expected under 'give_token_name' naming scheme});

  unlink 't/GiveNamesToCalc.pm';
}

