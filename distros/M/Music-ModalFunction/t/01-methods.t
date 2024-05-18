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
    is $obj->hash_results, 0, 'hash_results';
    is $obj->verbose, 0, 'verbose';
    is_deeply [sort keys %{ $obj->_modes }],
        [qw(aeolian dorian ionian locrian lydian mixolydian phrygian)],
        '_modes';
    is_deeply [sort keys %{ $obj->_scales }],
        [qw(augmented blues diminished harmonic_minor melodic_minor pentatonic pentatonic_minor)],
        '_scales';
    ok length($obj->_database), '_database';
    my @got = $obj->_database =~ /\n/g;
    is scalar(@got), 600, '_database';
};

subtest mode_chord_key => sub {
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
        chord_note   => 'd',
        chord        => 'maj',
        key_function => 'dominant',
        hash_results => 1,
    ];
    $got = $obj->chord_key;
    $expect = [
        { method => 'chord_key', chord_note => 'd', chord => 'maj', key_note => 'g', key => 'ionian', key_function => 'dominant', key_roman => 'r_V' },
        { method => 'chord_key', chord_note => 'd', chord => 'maj', key_note => 'g', key => 'lydian', key_function => 'dominant', key_roman => 'r_V' },
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


subtest scale_chord_key => sub {
    my $obj = new_ok 'Music::ModalFunction' => [
        chord_note   => 'd',
        chord        => 'maj',
        key_function => 'dominant',
        use_scales   => 1,
    ];
    my $got = $obj->chord_key;
    my $expect = [
        [ 'chord_key', 'd', 'maj', 'g', 'augmented', 'dominant', 'r_V' ],
        [ 'chord_key', 'd', 'maj', 'g', 'harmonic_minor', 'dominant', 'r_V' ],
        [ 'chord_key', 'd', 'maj', 'g', 'melodic_minor', 'dominant', 'r_V' ],
    ];
    is_deeply $got, $expect, 'chord_key';

    $obj = new_ok 'Music::ModalFunction' => [
        chord_note   => 'd',
        chord        => 'maj',
        key_function => 'dominant',
        hash_results => 1,
        use_scales   => 1,
    ];
    $got = $obj->chord_key;
    $expect = [
        {
            chord => 'maj',
            chord_note => 'd',
            key => 'augmented',
            key_function => 'dominant',
            key_note => 'g',
            key_roman => 'r_V',
            method => 'chord_key',
        }, {
            chord => 'maj',
            chord_note => 'd',
            key => 'harmonic_minor',
            key_function => 'dominant',
            key_note => 'g',
            key_roman => 'r_V',
            method => 'chord_key',
        }, {
            chord => 'maj',
            chord_note => 'd',
            key => 'melodic_minor',
            key_function => 'dominant',
            key_note => 'g',
            key_roman => 'r_V',
            method => 'chord_key',
        },
    ];
    is_deeply $got, $expect, 'chord_key';

    $obj = new_ok 'Music::ModalFunction' => [
        chord_note => 'g',
        chord      => 'maj',
        use_scales => 1,
    ];
    $got = $obj->chord_key;
    $expect = 15;
    is scalar(@$got), $expect, 'chord_key';
};

subtest mode_pivot_chord_keys => sub {
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
        chord_note   => 'g',
        chord        => 'maj',
        mode_note    => 'c',
        key_function => 'subdominant',
        hash_results => 1,
    ];
    $got = $obj->pivot_chord_keys;
    $expect = [
        { method => 'pivot_chord_keys', chord_note => 'g', chord => 'maj', mode_note => 'c', mode => 'ionian', mode_function => 'dominant', mode_roman => 'r_V', key_note => 'd', key => 'dorian', key_function => 'subdominant', key_roman => 'r_IV' },
        { method => 'pivot_chord_keys', chord_note => 'g', chord => 'maj', mode_note => 'c', mode => 'ionian', mode_function => 'dominant', mode_roman => 'r_V', key_note => 'd', key => 'ionian', key_function => 'subdominant', key_roman => 'r_IV' },
        { method => 'pivot_chord_keys', chord_note => 'g', chord => 'maj', mode_note => 'c', mode => 'ionian', mode_function => 'dominant', mode_roman => 'r_V', key_note => 'd', key => 'mixolydian', key_function => 'subdominant', key_roman => 'r_IV' },
        { method => 'pivot_chord_keys', chord_note => 'g', chord => 'maj', mode_note => 'c', mode => 'lydian', mode_function => 'dominant', mode_roman => 'r_V', key_note => 'd', key => 'dorian', key_function => 'subdominant', key_roman => 'r_IV' },
        { method => 'pivot_chord_keys', chord_note => 'g', chord => 'maj', mode_note => 'c', mode => 'lydian', mode_function => 'dominant', mode_roman => 'r_V', key_note => 'd', key => 'ionian', key_function => 'subdominant', key_roman => 'r_IV' },
        { method => 'pivot_chord_keys', chord_note => 'g', chord => 'maj', mode_note => 'c', mode => 'lydian', mode_function => 'dominant', mode_roman => 'r_V', key_note => 'd', key => 'mixolydian', key_function => 'subdominant', key_roman => 'r_IV' },
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

    $obj = Music::ModalFunction->new(
        mode_note    => 'c',
        mode         => 'ionian',
        key_note     => 'a',
        key          => 'aeolian',
    );
    $got = $obj->pivot_chord_keys;
    $expect = 7;
    is scalar(@$got), $expect, 'pivot_chord_keys';

    $obj = Music::ModalFunction->new(
        mode_note    => 'c',
        mode         => 'ionian',
        key_note     => 'gb',
        key          => 'ionian',
    );
    $got = $obj->pivot_chord_keys;
    $expect = 0;
    is scalar(@$got), $expect, 'pivot_chord_keys';
};

subtest scale_pivot_chord_keys => sub {
    my $obj = new_ok 'Music::ModalFunction' => [
        chord_note   => 'g',
        chord        => 'maj',
        mode_note    => 'c',
        key_function => 'subdominant',
        use_scales   => 1,
    ];
    my $got = $obj->pivot_chord_keys;
    my $expect = [
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'augmented', 'dominant', 'r_V', 'c', 'pentatonic', 'subdominant', 'r_IV' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'augmented', 'dominant', 'r_V', 'd', 'melodic_minor', 'subdominant', 'r_IV' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'harmonic_minor', 'dominant', 'r_V', 'c', 'pentatonic', 'subdominant', 'r_IV' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'harmonic_minor', 'dominant', 'r_V', 'd', 'melodic_minor', 'subdominant', 'r_IV' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'melodic_minor', 'dominant', 'r_V', 'c', 'pentatonic', 'subdominant', 'r_IV' ],
        [ 'pivot_chord_keys', 'g', 'maj', 'c', 'melodic_minor', 'dominant', 'r_V', 'd', 'melodic_minor', 'subdominant', 'r_IV' ],
    ];
    is_deeply $got, $expect, 'pivot_chord_keys';

    $obj = new_ok 'Music::ModalFunction' => [
        chord_note   => 'g',
        chord        => 'maj',
        mode_note    => 'c',
        key_function => 'subdominant',
        hash_results => 1,
        use_scales   => 1,
    ];
    $got = $obj->pivot_chord_keys;
    $expect = [
      {
        chord => 'maj',
        chord_note => 'g',
        key => 'pentatonic',
        key_function => 'subdominant',
        key_note => 'c',
        key_roman => 'r_IV',
        method => 'pivot_chord_keys',
        mode => 'augmented',
        mode_function => 'dominant',
        mode_note => 'c',
        mode_roman => 'r_V',
      }, {
        chord => 'maj',
        chord_note => 'g',
        key => 'melodic_minor',
        key_function => 'subdominant',
        key_note => 'd',
        key_roman => 'r_IV',
        method => 'pivot_chord_keys',
        mode => 'augmented',
        mode_function => 'dominant',
        mode_note => 'c',
        mode_roman => 'r_V',
      }, {
        chord => 'maj',
        chord_note => 'g',
        key => 'pentatonic',
        key_function => 'subdominant',
        key_note => 'c',
        key_roman => 'r_IV',
        method => 'pivot_chord_keys',
        mode => 'harmonic_minor',
        mode_function => 'dominant',
        mode_note => 'c',
        mode_roman => 'r_V',
      }, {
        chord => 'maj',
        chord_note => 'g',
        key => 'melodic_minor',
        key_function => 'subdominant',
        key_note => 'd',
        key_roman => 'r_IV',
        method => 'pivot_chord_keys',
        mode => 'harmonic_minor',
        mode_function => 'dominant',
        mode_note => 'c',
        mode_roman => 'r_V',
      }, {
        chord => 'maj',
        chord_note => 'g',
        key => 'pentatonic',
        key_function => 'subdominant',
        key_note => 'c',
        key_roman => 'r_IV',
        method => 'pivot_chord_keys',
        mode => 'melodic_minor',
        mode_function => 'dominant',
        mode_note => 'c',
        mode_roman => 'r_V',
      }, {
        chord => 'maj',
        chord_note => 'g',
        key => 'melodic_minor',
        key_function => 'subdominant',
        key_note => 'd',
        key_roman => 'r_IV',
        method => 'pivot_chord_keys',
        mode => 'melodic_minor',
        mode_function => 'dominant',
        mode_note => 'c',
        mode_roman => 'r_V',
      },
    ];
    is_deeply $got, $expect, 'pivot_chord_keys';

    $obj = new_ok 'Music::ModalFunction' => [
        chord_note => 'g',
        chord      => 'maj',
        key        => 'diminished',
        use_scales => 1,
    ];
    $got = $obj->pivot_chord_keys;
    $expect = 52;
    is scalar(@$got), $expect, 'pivot_chord_keys';

    $obj = Music::ModalFunction->new(
        mode_note  => 'c',
        mode       => 'diminished',
        key_note   => 'a',
        key        => 'diminished',
        use_scales => 1,
    );
    $got = $obj->pivot_chord_keys;
    $expect = 8;
    is scalar(@$got), $expect, 'pivot_chord_keys';

    $obj = Music::ModalFunction->new(
        mode_note  => 'c',
        mode       => 'diminished',
        key_note   => 'gb',
        key        => 'diminished',
        use_scales => 1,
    );
    $got = $obj->pivot_chord_keys;
    $expect = 0;
    is scalar(@$got), $expect, 'pivot_chord_keys';

    $obj = Music::ModalFunction->new(
        mode_note  => 'c',
        mode       => 'diminished',
        key_note   => 'c',
        key        => 'harmonic_minor',
        use_scales => 1,
    );
    $got = $obj->pivot_chord_keys;
    $expect = 2;
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
