#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Percussion::Tabla';

subtest defaults => sub {
    my $obj = new_ok 'Music::Percussion::Tabla';
    is $obj->verbose, 0, 'verbose';
    is $obj->channel, 0, 'channel';
    isa_ok $obj->score, 'MIDI::Simple';
    diag 'Soundfont file: ', $obj->soundfont;
    like $obj->soundfont, qr/\/Tabla\.sf2$/, 'soundfont';
};

subtest timidity_cfg => sub {
    my $obj = new_ok 'Music::Percussion::Tabla';
    like $obj->timidity_cfg, qr/\/Tabla\.sf2$/, 'timidity_cfg';
    my $filename = './timidity_cfg';
    $obj->timidity_cfg($filename);
    ok -e $filename, 'timidity_cfg with filename';
    unlink $filename;# or diag "Can't unlink $filename: $!";
    ok !-e $filename, 'file unlinked';
};

subtest score => sub {
    my $obj = new_ok 'Music::Percussion::Tabla';
    $obj->strike('tun');
    my @score = $obj->score->Score;
    is $score[4][0], 'note', 'note';
    is $score[4][4], 88, 'tun';
};

done_testing();
