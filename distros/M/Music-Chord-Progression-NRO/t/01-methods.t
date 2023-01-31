#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::Chord::Progression::NRO';

subtest throws => sub {
    throws_ok { Music::Chord::Progression::NRO->new(base_note => 'X') }
        qr/not a valid note/, 'bogus base_note';

    throws_ok { Music::Chord::Progression::NRO->new(base_octave => -1) }
        qr/not a valid octave/, 'bogus base_octave';

    throws_ok { Music::Chord::Progression::NRO->new(base_scale => 'foo') }
        qr/not a valid scale/, 'bogus base_scale';

    throws_ok { Music::Chord::Progression::NRO->new(format => 'foo') }
        qr/not a valid format/, 'bogus format';

    throws_ok { Music::Chord::Progression::NRO->new(max => -1) }
        qr/not a valid maximum/, 'bogus max';

    throws_ok { Music::Chord::Progression::NRO->new(transform => 'foo') }
        qr/not a valid transform/, 'bogus transform';

    throws_ok { Music::Chord::Progression::NRO->new(transform => {}) }
        qr/not a valid transform/, 'bogus transform';
};

subtest default => sub {
    my $obj = new_ok 'Music::Chord::Progression::NRO';
    my $got = $obj->generate;
    my $expect = 4;
    is @$got, $expect, "generated $expect chords";
    $expect = [qw(C4 E4 G4)];
    is_deeply $got->[0], $expect, 'generated 0th chord';
};

subtest transform_array => sub {
    my $obj = new_ok 'Music::Chord::Progression::NRO' => [
        transform => [qw(P P)],
    ];
    my $got = $obj->generate;
    no warnings qw(qw);
    my $expect = [[qw(C4 E4 G4)], [qw(C4 D#4 G4)], [qw(C4 E4 G4)] ];
    is_deeply $got, $expect, 'generated chords';
};

subtest transform_integer => sub {
    my $expect = 3;
    my $obj = new_ok 'Music::Chord::Progression::NRO' => [
        transform => $expect,
    ];
    my $got = $obj->generate;
    is @$got, $expect, "generated $expect chords";
    $expect = [qw(C4 E4 G4)];
    is_deeply $got->[0], $expect, 'generated 0th chord';
};

subtest transform_base => sub {
    my $obj = new_ok 'Music::Chord::Progression::NRO' => [
        base_note   => 'G',
        base_octave => 5,
    ];
    my $got = $obj->generate;
    my $expect = 4;
    is @$got, $expect, "generated $expect chords";
    $expect = [qw(G5 B5 D6)];
    is_deeply $got->[0], $expect, 'generated 0th chord';
};

subtest midinum_format => sub {
    my $obj = new_ok 'Music::Chord::Progression::NRO' => [
        format => 'midinum',
    ];
    my $got = $obj->generate;
    my $expect = [qw(60 64 67)];
    is_deeply $got->[0], $expect, 'generated 0th chord';
};

subtest circular => sub {
    my $expect = 4;
    my $obj = new_ok 'Music::Chord::Progression::NRO' => [
        transform => [qw(X P P)],
        max       => $expect,
    ];
    my $got = $obj->circular;
    is @$got, $expect, "generated $expect chords";
    $expect = [qw(C4 E4 G4)];
    is_deeply $got->[0], $expect, 'circular';
};

done_testing();
