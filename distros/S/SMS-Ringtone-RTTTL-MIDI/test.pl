#!/usr/bin/perl -w

use strict;
use SMS::Ringtone::RTTTL::Parser;
use SMS::Ringtone::RTTTL::MIDI qw(rtttl_to_midi);
use lib qw(lib);
use Test;

BEGIN {
 plan tests => 15;
}

while (<DATA>) {
 chomp;
 my $r = new SMS::Ringtone::RTTTL::Parser($_);
 if ($r->has_errors() || $r->has_warnings()) {
  ok(0);
  next;
 }
 my $midi = rtttl_to_midi($r);
 ok(defined($midi));
}

__DATA__
Addams Family:b=160,l=15,d=8,o=5:C,4F,A,4F,C,4B4,2G,F,4E,G,4E,C,4A4,2F,C,4F,A,4F,C,4B4,2G,F,4E,C,4D,E,1F,C,D,E,F,1P,C,D,F#,G,1P,D,E,F#,G,4P,D,E,F#,G,4P,C,D,E,F
bleedingme:b=180,l=15,d=8:4E5,4E,G,D,E,E5,E5,E,E5,A5,D,G,E,4E5,4E,G,D,E,E5,E,32E
blitzkrieg:b=180,l=15,d=8,o=5:4F,C6,D6,D,D,D6,C6,D6,D,D,D6,D,F6,D6,D,D,A,A#,D,32D,D,G,D,32D,D,4F6,C6,C6,D,D,D6
Cucaracha:b=125,l=15,d=8,o=5:P,G,G,G,4C6,P,E6,E6,G,G,G,4C6,P,E6,4E6,P,4C6,C6,B,B,A,A,2G,P,G,G,G,4B,P,D6,D6,G,G,G,4B,P,D6,4D6,P,4G6,A6,G6,F6,E6,D6,2C6
daytripper:b=125,l=15,d=8,o=5:4E,G,G#,B,E6,4D6,B,4F#6,B,D6,E6,4E,G,G#,B,E6,4D6,B,4F#6,B,D6,E6,4E,G,G#,B,E6,4D6,B,4F#6,B,D6,E6,4E,G,G#,B,E6,4D6,B,4F#6,B,D6,E6
flintstones:b=160,l=15,d=16,o=5:32G,8P,4C,P,8C6,P,32A,P,32G,8P,4C,P,8G,P,32F,P,32E,P,32E,P,32F,P,32G,P,C,8P,32D,8P,4E,P,G,8P,4C,P,C6,8P,32A,P,G,8P,4C,P,G,8P,32F,P,32E,P,32E,P,32F,P
heartshapedbox:b=180,l=15,o=5:A,E6,A6,E6,F,C6,E6,C6,D,P,A,B,P,A,8D6,8A,8A,A,E6,A6,E6,F,C6,F,C6,D,8F,8F#,8F#,8F#,8F#,8C,32C
jimihendrixheyj:b=180,l=15:C,E,F,F#,G5,B5,C,C#,D,8F#,8G5,8G5,G#5,A5,C#,D,D#,E,8P5,8E,E,P5,A#5,8D,8B5,32B5,8G,8E,8E,8P5,8E,E
Kylie:b=140,l=15,o=5:F,F,F.,16P,F,F,8F,F,8G,8P,E,E,E.,16P,E,E,8E,E,8D,8P,F,F,F.,16P,F,F,8F,F,8G,8P,E,E,E.,16P,E,E,8E,E,8D,8P
masterofpuppets:b=180,l=15,d=8,o=5:4E6,4P,D6,P,C#6,P,C6,P,E,E,E6,E,E,D#6,E,E,D6,P,C#6,P,C6,E,E,B,E,E,A#,E,E,A,E,G#,E,G,E
outofnthngatall:b=70,l=15,d=16:8G,8D,8G,8A,8C7,B,C7,B,A,G,F#,8G,8D,8G,8A,8C7,B,C7,B,A,G,F#,8G,8E,8G,8A,8C7,B,C7,B,A,G,F#,8G,8E,8G,8A,8C7,B,C7,B,A,G,F#
simpsons:b=160,l=15,d=8,o=5:4C6,4E6,4F#6,A6,4G6,4E6,4C6,A,F#,F#,F#,2G,4P,F#,F#,F#,G,4A#,C6
twilightzone:b=180,l=15:C,C#,C,A5,C,C#,C,A5,C,C#,C,A5,C,C#,C
usa:b=125,l=15,o=5:8G,16E,C,E,G,2C6,8E6,16D6,C6,E,F#,2G,G,E6,8D6,C6,2B,8A,16B,C6,C6,G,E,C
welcomehome:b=180,l=15,o=5:E,B,F#6,G6,E,C6,G6,8G6,8E,8E,D6,A6,G6,A,C#6,D6,8A,8G,B,D6,8G,8A