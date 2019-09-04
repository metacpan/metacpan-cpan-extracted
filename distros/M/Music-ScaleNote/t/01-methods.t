#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::ScaleNote';

my $msn = Music::ScaleNote->new(
    scale_name => 'pminor',
#    verbose    => 1,
);
isa_ok $msn, 'Music::ScaleNote';

throws_ok {
    $msn->get_offset( note_name => 'C#' );
} qr/Scale position not defined/, 'note_name not in scale';

my $format = 'midinum';
my $note = $msn->get_offset(
    note_name   => 60,
    note_format => $format,
);
isa_ok $note, 'Music::Note';
is $note->format($format), 63, 'get_offset';

$format = 'ISO';
is $note->format($format), 'D#4', 'get_offset';

$note = $msn->get_offset(
    note_name => 'D#4',
    offset    => -1,
);
isa_ok $note, 'Music::Note';
is $note->format($format), 'C4', 'get_offset';

$note = $msn->get_offset(
    note_name => 'D#',
    offset    => -1,
);
isa_ok $note, 'Music::Note';
is $note->format($format), 'C4', 'get_offset';

$format = 'midinum';
is $note->format($format), 60, 'get_offset';

$format = 'isobase';
$note = $msn->get_offset(
    note_name   => 'D#',
    note_format => $format,
    offset      => -1,
);
isa_ok $note, 'Music::Note';
is $note->format($format), 'C', 'get_offset';

$format = 'midi';
$note = $msn->get_offset(
    note_name   => 'C',
    note_format => $format,
    offset      => -1,
);
isa_ok $note, 'Music::Note';
is $note->format($format), 'As3', 'get_offset';

$msn = Music::ScaleNote->new( scale_note => 'X' );
isa_ok $msn, 'Music::ScaleNote';

throws_ok {
    $msn->get_offset;
} qr/Scale position not defined/, 'scale_note not defined';

done_testing();
