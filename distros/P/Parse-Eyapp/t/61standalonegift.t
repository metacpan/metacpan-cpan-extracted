#!/usr/bin/perl -w
use strict;
use Test::More tests=>3;

SKIP: {
  skip "Gift.yp not found", 3 unless ($ENV{DEVELOPER} && -r "t/Gift.yp" && -x "./eyapp");

  unlink 't/Gift.pm';

  my $r = system('perl -I./lib/ eyapp -s t/Gift.yp');
  
  ok(!$r, "standalone option");

  ok(-s "t/Gift.pm", ".pm generated with standalone");

  my $eyapppath;
  eval {
    local $ENV{PERL5LIB};
    $eyapppath = shift @INC; # Supress ~/LEyapp/lib from search path

    require "t/Gift.pm";
  };
  ok(!$@, "standalone generated module loaded");

  unlink 't/Gift.pm';
}
