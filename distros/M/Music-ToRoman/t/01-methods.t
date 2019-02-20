#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::ToRoman';

my $mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'minor',
);
isa_ok $mtr, 'Music::ToRoman';

is $mtr->parse('Am'), 'i', 'i';
is $mtr->parse('B'), 'II', 'II';
is $mtr->parse('Bo'), 'iio', 'iio';
is $mtr->parse('Bdim'), 'iio', 'iio';
is $mtr->parse('CM'), 'III', 'III';
is $mtr->parse('Cm9/G'), 'iii9/VII', 'iii9/VII';
throws_ok { $mtr->parse('Cm9/Bb') }
    qr/non-scale note in bass/, "can't parse Cm9/Bb";
is $mtr->parse('Em7'), 'v7', 'v7';
is $mtr->parse('E7'), 'V7', 'V7';
is $mtr->parse('A+'), 'I+', 'I+';
is $mtr->parse('BbM'), 'bII', 'bII';
is $mtr->parse('Bm sus4'), 'ii sus4', 'ii sus4';
is $mtr->parse('Bmin7'), 'ii min7', 'ii min7';
is $mtr->parse('AMaj7'), 'I maj7', 'I maj7';

$mtr = Music::ToRoman->new(
    scale_note => 'A',
    scale_name => 'dorian',
    chords     => 0,
);
is $mtr->parse('A'), 'i', 'i';
is $mtr->parse('B'), 'ii', 'ii';
is $mtr->parse('C'), 'III', 'III';
is $mtr->parse('D'), 'IV', 'IV';
is $mtr->parse('E7'), 'v7', 'v7';
is $mtr->parse('F#'), 'vi', 'vi';
is $mtr->parse('G'), 'VII', 'VII';

done_testing();
