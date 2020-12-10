#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Chord::Progression';

my $obj = new_ok 'Music::Chord::Progression';

my $got = $obj->generate;
is scalar @$got, 8, 'generate';
is_deeply $got->[0], ['C4','E4','G4'], 'generate';
is_deeply $got->[-1], ['C4','E4','G4'], 'generate';

$obj = new_ok 'Music::Chord::Progression' => [
    scale_note => 'B',
];
$got = $obj->generate;
is_deeply $got->[0], ['B4','D#5','F#5'], 'generate';
is_deeply $got->[-1], ['B4','D#5','F#5'], 'generate';

$obj = new_ok 'Music::Chord::Progression' => [
    scale_note => 'Bb',
    flat => 1,
#    verbose => 1,
];
$got = $obj->generate;
is_deeply $got->[0], ['Bb4','D5','F5'], 'flat';

done_testing();
