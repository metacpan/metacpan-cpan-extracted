#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::ScaleNote';

subtest throws => sub {
    my $msn = new_ok 'Music::ScaleNote' => [ scale_name => 'pminor' ];
    throws_ok {
        $msn->get_offset( note_name => 'C#' );
    } qr/Scale position not defined/, 'note_name not in scale';

    $msn = new_ok 'Music::ScaleNote' => [ scale_note => 'X' ];
    throws_ok {
        $msn->get_offset;
    } qr/Scale position not defined/, 'scale_note not defined';
};

subtest offsets => sub {
    my $msn = new_ok 'Music::ScaleNote' => [ scale_name => 'pminor' ];

    my $format = 'midinum';
    my $note = $msn->get_offset(
        note_name   => 63,
        note_format => $format,
    );
    isa_ok $note, 'Music::Note';
    is $note->format($format), 65, 'get_offset';

    $format = 'ISO';
    is $note->format($format), 'F4', 'get_offset';

    $format = 'midinum';
    $note = $msn->get_offset(
        note_name   => 60,
        note_format => $format,
        offset      => -1,
    );
    is $note->format($format), 58, 'get_offset';

    $format = 'ISO';
    $note = $msn->get_offset(
        note_name => 'D#4',
        offset    => -1,
    );
    is $note->format($format), 'C4', 'get_offset';

    $note = $msn->get_offset(
        note_name => 'D#',
        offset    => -1,
    );
    is $note->format($format), 'C4', 'get_offset';

    $format = 'midinum';
    is $note->format($format), 60, 'get_offset';

    $format = 'isobase';
    $note = $msn->get_offset(
        note_name   => 'D#',
        note_format => $format,
        offset      => -1,
    );
    is $note->format($format), 'C', 'get_offset';

    $format = 'midi';
    $note = $msn->get_offset(
        note_name   => 'C',
        note_format => $format,
        offset      => -1,
        flat        => 1,
    );
    is $note->format($format), 'Bf3', 'get_offset';
};

subtest steps => sub {
    my $msn = new_ok 'Music::ScaleNote' => [ scale_name => 'pminor' ];

    my $format = 'midi';

    my $note = $msn->step( note_name => 'C' );
    isa_ok $note, 'Music::Note';
    is $note->format($format), 'Cs4', 'step';

    $note = $msn->step(
        note_name => 'C',
        steps     => -1,
    );
    is $note->format($format), 'B3', 'step';

    $note = $msn->step(
        note_name => 'D4',
        steps     => -1,
    );
    is $note->format($format), 'Cs4', 'step';

    $note = $msn->step(
        note_name => 'D4',
        steps     => -1,
        flat      => 1,
    );
    is $note->format($format), 'Df4', 'step';

    $note = $msn->step(
        note_name => 'D4',
        steps     => -2,
        flat      => 1,
    );
    is $note->format($format), 'C4', 'step';

    $format = 'midinum';
    $msn = new_ok 'Music::ScaleNote' => [
        scale_note  => 'D',
        note_format => $format,
    #    verbose     => 1,
    ];

    $note = $msn->step(
        note_name => 62,
        steps     => 2,
    );
    is $note->format($format), 64, 'step';
};

done_testing();
