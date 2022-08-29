#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::Chord::Progression';

subtest defaults => sub {
    my $obj = new_ok 'Music::Chord::Progression';
    my $expect = ['C4','E4','G4'];
    my $got = $obj->generate;
    is scalar @$got, $obj->max, 'generate';
    is_deeply $got->[0], $expect, 'generate';
    is_deeply $got->[-1], $expect, 'generate';
    is_deeply $got, $obj->chords, 'generate';

    is @{ $obj->phrase }, $obj->max, 'phrase length';
    is @{ $obj->chords }, $obj->max, 'chords length';
};

subtest scale_note => sub {
    my $obj = new_ok 'Music::Chord::Progression' => [
        scale_note => 'Bb',
    ];
    my $expect = ['A#4','D5','F5'];
    my $got = $obj->generate;
    is_deeply $got->[0], $expect, 'generate';
    is_deeply $got->[-1], $expect, 'generate';

    $obj = new_ok 'Music::Chord::Progression' => [
        scale_note => 'A',
        scale_name => 'minor',
        chord_map  => ['m','dim','','m','m','',''],
    ];
    $expect = ['A4','C5','E5'];
    $got = $obj->generate;
    is_deeply $got->[0], $expect, 'generate';
    is_deeply $got->[-1], $expect, 'generate';
};

subtest flattening => sub {
    my $obj = new_ok 'Music::Chord::Progression' => [
        scale_note => 'Bb',
        flat       => 1,
    ];
    my $expect = ['Bb4','D5','F5'];
    my $got = $obj->generate;
    is_deeply $got->[0], $expect, 'flat';
    is_deeply $got->[-1], $expect, 'flat';
};

subtest substitution => sub {
    my $obj = new_ok 'Music::Chord::Progression' => [
        scale_note => 'Bb',
        flat       => 1,
    ];
    my $got = $obj->substitution('');
    ok $got eq 7 || $got eq 'M7', 'substitution';
    $got = $obj->substitution('m');
    ok $got eq 'm7' || $got eq 'mM7', 'substitution';
    $got = $obj->substitution(7);
    ok $got eq 9 || $got eq 11 || $got eq 13, 'substitution';

    # Always substitute
    $obj = new_ok 'Music::Chord::Progression' => [
        max        => 3,
        substitute => 1,
        sub_cond   => sub { 1 },
    ];
    $got = $obj->generate;
    ok @$_ > 3, 'sub_cond' for @$got;
};

subtest net => sub {
    my $obj = new_ok 'Music::Chord::Progression' => [
        max => 7,
        net => { 1 => [2], 2 => [3], 3 => [4], 4 => [5], 5 => [6], 6 => [7], 7 => [1] },
        resolve => 0,
    #    verbose => 1,
    ];
    my $expect = [
        ['C4','E4','G4'], ['D4','F4','A4'], ['E4','G4','B4'],
        ['F4','A4','C5'], ['G4','B4','D5'], ['A4','C5','E5'],
        ['B4','D5','F5'],
    ];
    my $got = $obj->generate;
    is_deeply $got, $expect, 'generate';
};

subtest chord_map => sub {
    my $obj = new_ok 'Music::Chord::Progression' => [
        chord_map => [''],
    ];
    throws_ok { $obj->generate }
        qr/chord_map length must equal number of net keys/, 'invalid chord_map';
};

done_testing();
