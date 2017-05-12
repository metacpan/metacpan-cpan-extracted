#!/usr/bin/perl -w
use strict;
use Test::More tests=>8;
#use_ok qw(Parse::Eyapp) or exit;

SKIP: {
  skip "Calc.eyp not found", 8 unless ($ENV{DEVELOPER} && -r "t/Calc.eyp" && -x "./eyapp");

  unlink 't/Calc.pm';

  my $r = system('perl -I./lib/ eyapp -s t/Calc.eyp');
  
  ok(!$r, "standalone option");

  ok(-s "t/Calc.pm", ".pm generated with standalone");

  my $eyapppath;
  eval {
    local $ENV{PERL5LIB};
    $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path

    require "t/Calc.pm";
  };
  ok(!$@, "standalone generated module loaded");

  my $parser = Calc->new();
  my $input = "a = 3*2\nb = 4*a\nc = a*b\n";
  my $t = $parser->Run(\$input);
  my %r = ( a => 6, b => 24, c => 144);
  is($t->{$_}, $r{$_}, "Using calc: $_ is $r{$_}") for (qw{a b c});

  unshift @INC, $eyapppath;
  my $warning = '';
  local $SIG{__WARN__} = sub { $warning = shift };
  eval {

    use_ok qw{Parse::Eyapp};

  };
  ok(!$warning, "Parse::Eyapp loaded on top of standalone without warnings");

  unlink 't/Calc.pm';

}
