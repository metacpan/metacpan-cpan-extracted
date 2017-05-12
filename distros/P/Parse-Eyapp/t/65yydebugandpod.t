#!/usr/bin/perl -w
use strict;
use Test::More tests=>4;
use_ok qw(Parse::Eyapp) or exit;

SKIP: {
  skip "Debug2.eyp not found", 3 unless ($ENV{DEVELOPER} && -r "t/Debug2.eyp" && -x "./eyapp");

  unlink 't/Debug2.pm';

  my $r = system('perl -I./lib/ eyapp t/Debug2.eyp');
  
  ok(!$r, "yydebug option activated");

  ok(-s "t/Debug2.pm", ".pm generated with yydebug");

  unshift @INC, 't/';
  require Debug2;

  my $parser = Debug2->new();

  my $input = "D\n\n;S\n\n";

  open(STDERR, ">", "t/err");
  open(STDOUT, ">", "t/out");
  $parser->Run($input);
my $begideb = quotemeta(<< 'BEGDEB');
----------------------------------------
In state 0:
Stack: 0
Need token. Got >D<
Shift and go to state 4.
BEGDEB

  my $x = `cat t/err`;

  like($x, qr{$begideb}, 'yydebug output looks ok');

  unlink 't/Debug2.pm';
  unlink 't/err';
  unlink 't/out';
}
