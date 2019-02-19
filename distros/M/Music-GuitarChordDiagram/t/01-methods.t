#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::GuitarChordDiagram';

my $obj = Music::GuitarChordDiagram->new( chord => 'xxxxxx' );
isa_ok $obj, 'Music::GuitarChordDiagram';

is $obj->chord, 'xxxxxx', 'chord';
is $obj->position, 1, 'position';
is $obj->strings, 6, 'strings';
is $obj->frets, 5, 'frets';
is $obj->size, 30, 'size';
is $obj->outfile, 'chord-diagram', 'outfile';
like $obj->font, qr/\.ttf/, 'font';
is_deeply $obj->tuning, [qw/E B G D A E/], 'tuning';
is keys %{ $obj->fretboard }, 6, 'fretboard';
is scalar @{ $obj->fretboard->{1} }, 12, 'fretboard';
is $obj->verbose, 0, 'verbose';

can_ok $obj, 'draw';

done_testing();
