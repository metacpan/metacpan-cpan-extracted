#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::MelodicDevice::Transposition';

my @notes = qw(C4 E4 D4 G4 C5);
my @nums  = qw(60 64 62 67 72);

my $obj = new_ok 'Music::MelodicDevice::Transposition';# => [ verbose => 1 ];

subtest one => sub {
  my $expect = ['D4','F#4','E4','A4','D5'];
  my $got = $obj->transpose(2, \@notes);
  is_deeply $got, $expect, 'transpose up 2';
  $expect = ['E4','G#4','F#4','B4','E5'];
  $got = $obj->transpose(4, \@notes);
  is_deeply $got, $expect, 'transpose up 4';
  $expect = ['A#3','D4','C4','F4','A#4'];
  $got = $obj->transpose(-2, \@notes);
  is_deeply $got, $expect, 'transpose down 2';
  $expect = ['G#3','C4','A#3','D#4','G#4'];
  $got = $obj->transpose(-4, \@notes);
  is_deeply $got, $expect, 'transpose down 4';
};

subtest two => sub {
    my $expect = [62,66,64,69,74];
    my $got = $obj->transpose(2, \@nums);
    is_deeply $got, $expect, 'transpose up 2';
    $expect = [64,68,66,71,76];
    $got = $obj->transpose(4, \@nums);
    is_deeply $got, $expect, 'transpose up 4';
    $expect = [58,62,60,65,70];
    $got = $obj->transpose(-2, \@nums);
    is_deeply $got, $expect, 'transpose down 2';
    $expect = [56,60,58,63,68];
    $got = $obj->transpose(-4, \@nums);
    is_deeply $got, $expect, 'transpose down 4';
};

$obj = new_ok 'Music::MelodicDevice::Transposition' => [
    scale_name => 'major',
#    verbose => 1,
];

subtest three => sub {
    my $expect = ['E4','G4','F4','B4','E5'];
    my $got = $obj->transpose(2, \@notes);
    is_deeply $got, $expect, 'transpose up 2';
    $expect = ['G4','B4','A4','D5','G5'];
    $got = $obj->transpose(4, \@notes);
    is_deeply $got, $expect, 'transpose up 4';
    $expect = ['A3','C4','B3','E4','A4'];
    $got = $obj->transpose(-2, \@notes);
    is_deeply $got, $expect, 'transpose down 2';
    $expect = ['F3','A3','G3','C4','F4'];
    $got = $obj->transpose(-4, \@notes);
    is_deeply $got, $expect, 'transpose down 4';
};

subtest four => sub {
    my $expect = [64,67,65,71,76];
    my $got = $obj->transpose(2, \@nums);
    is_deeply $got, $expect, 'transpose up 2';
    $expect = [67,71,69,74,79];
    $got = $obj->transpose(4, \@nums);
    is_deeply $got, $expect, 'transpose up 4';
    $expect = [57,60,59,64,69];
    $got = $obj->transpose(-2, \@nums);
    is_deeply $got, $expect, 'transpose down 2';
    $expect = [53,57,55,60,65];
    $got = $obj->transpose(-4, \@nums);
    is_deeply $got, $expect, 'transpose down 4';
};

subtest five => sub {
    my @notes = ('C4','E4','D#4','G4','C5');
    my $expect = ['E4','G4',undef,'B4','E5'];
    my $got = $obj->transpose(2, \@notes);
    is_deeply $got, $expect, 'transpose unknown';
};

subtest six => sub {
    my @nums  = qw(60 64 63 67 72);
    my $expect = [64,67,undef,71,76];
    my $got = $obj->transpose(2, \@nums);
    is_deeply $got, $expect, 'transpose unknown';
};

subtest seven => sub {
    my @notes = ('C4','E4','G4');
    my $expect = [qw(G4 B4 D5)];
    $obj->notes(\@notes);
    my $got = $obj->transpose(4);
    is_deeply $got, $expect, 'transpose notes';
};

done_testing();
