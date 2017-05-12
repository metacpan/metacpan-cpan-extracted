#!/usr/bin/perl
use Music::Abc::DT qw( get_time get_time_ql $c_voice %voice_struct $sym );
use Test::More tests => 2;
use strict;
use warnings;

subtest 'get_time' => sub {
  plan tests => 1;

  my $time = 1152; # equivalent to 3 quarter lengths
  # $sym->{info}->{time} = $time;
  $c_voice = 0;
  $voice_struct{$c_voice}{time} = $time;

  is(
      $time,
      get_time(),
      'get_time() returns the time elapsed until this moment in the current voice'
    );
};

subtest 'get_time_ql' => sub {
  plan tests => 1;

  my $time = 1152; # equivalent to 3 quarter lengths
  # $sym->{info}->{time} = $time;
  $c_voice = 0;
  $voice_struct{$c_voice}{time} = $time;

  is(
      $time / 384,
      get_time_ql(),
      'get_time_ql() returns the time elapsed in quarter lengths until this moment in the current voice'
    );
};

done_testing;
