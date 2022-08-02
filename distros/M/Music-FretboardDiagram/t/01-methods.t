#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::FretboardDiagram';

use constant BOGUS => 'foo';
use constant CHORD => 'xxxxxx';

subtest throws => sub {
    throws_ok {
        Music::FretboardDiagram->new( position => BOGUS )
    } qr/not a positive integer/, 'bogus position dies';

    throws_ok {
        Music::FretboardDiagram->new( strings => BOGUS )
    } qr/not a positive integer/, 'bogus strings dies';

    throws_ok {
        Music::FretboardDiagram->new( frets => BOGUS )
    } qr/not a positive integer/, 'bogus frets dies';

    throws_ok {
        Music::FretboardDiagram->new( size => BOGUS )
    } qr/not a positive integer/, 'bogus size dies';

    throws_ok {
        Music::FretboardDiagram->new( horiz => BOGUS )
    } qr/not a Boolean/, 'bogus horiz dies';

    throws_ok {
        Music::FretboardDiagram->new( image => BOGUS )
    } qr/not a Boolean/, 'bogus image dies';

    throws_ok {
        Music::FretboardDiagram->new( verbose => BOGUS )
    } qr/not a Boolean/, 'bogus verbose dies';

    throws_ok {
        Music::FretboardDiagram->new( absolute => BOGUS )
    } qr/not a Boolean/, 'bogus absolute dies';

    throws_ok {
        Music::FretboardDiagram->new( chord => '54321' )
    } qr/chord length and string number differ/, 'chord length not equal to strings';
};

subtest attrs => sub {
    my $obj = new_ok 'Music::FretboardDiagram' => [ chord => CHORD ];

    is_deeply $obj->chord, [[1,CHORD]], 'chord';
    is $obj->position, 1, 'position';
    is $obj->absolute, 0, 'absolute';
    is $obj->strings, 6, 'strings';
    is $obj->frets, 5, 'frets';
    is $obj->size, 30, 'size';
    is $obj->outfile, 'chord-diagram', 'outfile';
    is $obj->type, 'png', 'type';
    like $obj->font, qr/\.ttf$/, 'font';
    is $obj->horiz, 0, 'horiz';
    is $obj->string_color, 'blue', 'string_color';
    is $obj->fret_color, 'darkgray', 'fret_color';
    is_deeply $obj->tuning, [qw/E B G D A E/], 'tuning';
    is keys %{ $obj->fretboard }, 6, 'fretboard';
    is scalar @{ $obj->fretboard->{1} }, 12, 'fretboard';
    is $obj->showname, 1, 'showname';
    is $obj->verbose, 0, 'verbose';
};

subtest _note_at => sub {
    my $obj = new_ok 'Music::FretboardDiagram' => [ chord => CHORD ];

    my $note = 0;
    my $posn = $obj->position;
    my $got = $obj->_note_at($posn, 1, $note);
    is $got, 'E', 'open E';
    $note = 1;
    $got = $obj->_note_at($posn, 1, $note);
    is $got, 'F', '1st fret F';

    $note = 0;
    $posn = 13;
    $got = $obj->_note_at($posn, 1, $note);
    is $got, 'E', '12th fret E';
    $note = 1;
    $got = $obj->_note_at($posn, 1, $note);
    is $got, 'F', '13th fret F';

    $note = 0;
    $posn = 25;
    $got = $obj->_note_at($posn, 1, $note);
    is $got, 'E', '24th fret E';
    $note = 1;
    $got = $obj->_note_at($posn, 1, $note);
    is $got, 'F', '25th fret F';
};

subtest image => sub {
    my $obj = new_ok 'Music::FretboardDiagram' => [
        chord => CHORD,
        image => 1,
    ];
    my $got = $obj->draw;
    isa_ok $got, 'Imager', 'returned image';
};

subtest spec_to_notes => sub {
    my $obj = new_ok 'Music::FretboardDiagram' => [ chord => CHORD ];
    my $got = $obj->spec_to_notes($obj->chord->[0][1]);
    my $expect = [];
    is_deeply $got, $expect, 'spec_to_notes';

    $got = $obj->spec_to_notes('x02220');
    $expect = [qw(A E A Db E)];
    is_deeply $got, $expect, 'spec_to_notes';

    $obj->position(2);
    $got = $obj->spec_to_notes('x02220');
    $expect = [qw(A F Bb D E)];
    is_deeply $got, $expect, 'spec_to_notes';
};

done_testing();
