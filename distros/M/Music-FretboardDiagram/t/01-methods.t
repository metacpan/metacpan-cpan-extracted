#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::FretboardDiagram';

my $obj;

throws_ok {
    $obj = Music::FretboardDiagram->new( position => 'foo' )
} qr/not a positive integer/, 'bogus position dies';
throws_ok {
    $obj = Music::FretboardDiagram->new( strings => 'foo' )
} qr/not a positive integer/, 'bogus strings dies';
throws_ok {
    $obj = Music::FretboardDiagram->new( frets => 'foo' )
} qr/not a positive integer/, 'bogus frets dies';
throws_ok {
    $obj = Music::FretboardDiagram->new( size => 'foo' )
} qr/not a positive integer/, 'bogus size dies';
throws_ok {
    $obj = Music::FretboardDiagram->new( chord => '54321' )
} qr/chord length and string number differ/, 'chord length not equal to strings';

$obj = Music::FretboardDiagram->new( chord => 'xxxxxx' );
isa_ok $obj, 'Music::FretboardDiagram';

is $obj->chord, 'xxxxxx', 'chord';
is $obj->position, 1, 'position';
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

can_ok $obj, 'draw';

my $note = 0;
my $x = $obj->_note_at(1, $note);
is $x, 'E', 'open E';
$note = 1;
$x = $obj->_note_at(1, $note);
is $x, 'F', '1st fret F';

$note = 0;
$obj->position(13);
$x = $obj->_note_at(1, $note);
is $x, 'E', '12th fret E';
$note = 1;
$x = $obj->_note_at(1, $note);
is $x, 'F', '13th fret F';

$note = 0;
$obj->position(25);
$x = $obj->_note_at(1, $note);
is $x, 'E', '24th fret E';
$note = 1;
$x = $obj->_note_at(1, $note);
is $x, 'F', '25th fret F';

done_testing();
