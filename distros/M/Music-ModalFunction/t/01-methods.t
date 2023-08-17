#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::ModalFunction';

subtest defaults => sub {
    my $obj = new_ok 'Music::ModalFunction';
    is $obj->chord_note, undef, 'chord_note';
    is $obj->chord, undef, 'chord';
    is $obj->mode_note, undef, 'mode_note';
    is $obj->mode, undef, 'mode';
    is $obj->mode_function, undef, 'mode_function';
    is $obj->mode_roman, undef, 'mode_roman';
    is $obj->key_note, undef, 'key_note';
    is $obj->key, undef, 'key';
    is $obj->key_function, undef, 'key_function';
    is $obj->key_roman, undef, 'key_roman';
    is $obj->verbose, 0, 'verbose';
    is_deeply [sort keys %{ $obj->_modes }],
        [qw(aeolian dorian ionian locrian lydian mixolydian phrygian)],
        '_modes';
    ok length($obj->_database), '_database';
    my @got = $obj->_database =~ /\n/g;
    is scalar(@got), 602, '_database';
};

subtest chord_key => sub {
    my $obj = new_ok 'Music::ModalFunction' => [
        chord_note   => 'd',
        chord        => 'maj',
        key_function => 'dominant',
    ];
    my $got = $obj->chord_key;
    my $expect = [
        [ 'chord_key', 'd', 'maj', 'g', 'ionian', 'dominant', 'r_V' ],
        [ 'chord_key', 'd', 'maj', 'g', 'lydian', 'dominant', 'r_V' ],
    ];
    is_deeply $got, $expect, 'chord_key';

    $obj = new_ok 'Music::ModalFunction' => [
        chord_note => 'g',
        chord      => 'maj',
    ];
    $got = $obj->chord_key;
    $expect = 18;
    is scalar(@$got), $expect, 'chord_key';
};

subtest pivot_chord_keys => sub {
    my $obj = new_ok 'Music::ModalFunction' => [
        chord_note   => 'g',
        chord        => 'maj',
        mode_note    => 'c',
        key_function => 'subdominant',
    ];
    my $got = $obj->pivot_chord_keys;
    my $expect = [
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'ionian', 'dominant', 'r_V', 'd', 'dorian', 'subdominant', 'r_IV' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'ionian', 'dominant', 'r_V', 'd', 'ionian', 'subdominant', 'r_IV' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'ionian', 'dominant', 'r_V', 'd', 'mixolydian', 'subdominant', 'r_IV' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'lydian', 'dominant', 'r_V', 'd', 'dorian', 'subdominant', 'r_IV' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'lydian', 'dominant', 'r_V', 'd', 'ionian', 'subdominant', 'r_IV' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'lydian', 'dominant', 'r_V', 'd', 'mixolydian', 'subdominant', 'r_IV' ],
    ];
    is_deeply $got, $expect, 'pivot_chord_keys';

    $obj = new_ok 'Music::ModalFunction' => [
        chord_note => 'g',
        chord      => 'maj',
        key        => 'aeolian',
    ];
    $got = $obj->pivot_chord_keys;
    $expect = 45;
    is scalar(@$got), $expect, 'pivot_chord_keys';
};

subtest roman_key => sub {
    my $obj = new_ok 'Music::ModalFunction' => [
        mode       => 'ionian',
        mode_roman => 'r_i',
        key        => 'aeolian',
    ];
    my $got = $obj->roman_key;
    my $expect = 0;
    is scalar(@$got), $expect, 'pivot_chord_keys';
};

done_testing();
