#!/usr/bin/perl -w
use strict;
use Test::More tests=>3;

SKIP: {
  skip "pascal.yp not found", 3 unless ($ENV{DEVELOPER} && -r "t/pascal.yp" && -x "./eyapp");

  unlink 't/pascal.pm';

  my $r = `perl -I./lib/ eyapp t/pascal.yp 2>&1`;
  
  ok(!$r, "dos file with CRLF processed");

  ok(-s "t/pascal.pm", ".pm generated with dos file");

  eval {
    require "t/pascal.pm";
  };
  ok(!$@, "generated module from dos file loaded");

  unlink 't/pascal.pm';
}
