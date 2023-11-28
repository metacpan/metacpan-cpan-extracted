#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use constant BOGUS   => 'foo';
use constant VERBOSE => 0;

my $module = 'Music::Bassline::Generator';

use_ok $module;

subtest throws => sub {
    throws_ok { $module->new(guitar => BOGUS) }
        qr/not a boolean/, 'bogus guitar';
    throws_ok { $module->new(modal => BOGUS) }
        qr/not a boolean/, 'bogus modal';
    throws_ok { $module->new(chord_notes => BOGUS) }
        qr/not a boolean/, 'bogus chord_notes';
    throws_ok { $module->new(tonic => BOGUS) }
        qr/not a boolean/, 'bogus tonic';
    throws_ok { $module->new(verbose => BOGUS) }
        qr/not a boolean/, 'bogus verbose';
    throws_ok { $module->new(keycenter => BOGUS) }
        qr/not a valid pitch/, 'bogus keycenter';
    throws_ok { $module->new(intervals => BOGUS) }
        qr/not an array reference/, 'bogus intervals';
    throws_ok { $module->new(octave => BOGUS) }
        qr/not a positive integer/, 'bogus octave';
    throws_ok { $module->new(scale => BOGUS) }
        qr/not a code reference/, 'bogus scale';
    throws_ok { $module->new(wrap => BOGUS) }
        qr/not valid/, 'bogus wrap';
};

subtest attrs => sub {
    my $obj = new_ok $module => [
        verbose => VERBOSE,
    ];

    is $obj->octave, 1, 'octave';

    my $expect = [qw(-3 -2 -1 1 2 3)];
    is_deeply $obj->intervals, $expect, 'intervals';

    my $got = ref $obj->scale;
    is $got, 'CODE', 'scale';
};

subtest scale => sub {
    my $obj = new_ok $module => [
        verbose => VERBOSE,
    ];
    my $got = $obj->scale->('C7b5');
    is $got, 'major', 'scale';
    $got = $obj->scale->('Dm7b5');
    is $got, 'minor', 'scale';
    $got = $obj->scale->('D#/A#');
    is $got, 'major', 'scale';
};

subtest modal => sub {
    my $obj = new_ok $module => [
        verbose => VERBOSE,
        modal   => 1,
    ];
    my $got = $obj->scale->('C7b5');
    is $got, 'ionian', 'scale';
    $got = $obj->scale->('Dm7b5');
    is $got, 'dorian', 'scale';
};

subtest generate => sub {
    my $obj = new_ok $module => [
        verbose => VERBOSE,
    ];

    my $got = $obj->generate('C7b5', 4);
    is scalar(@$got), 4, 'generate';

    $got = $obj->generate('D/A', 4);
    is scalar(@$got), 4, 'generate';

    $got = $obj->generate('D', 4, 'C/G');
    is scalar(@$got), 4, 'generate';

    $got = $obj->generate('D', 1);
    is scalar(@$got), 1, 'generate';

    $obj = new_ok $module => [
        verbose => VERBOSE,
        tonic   => 1,
    ];
    my $expect = 24; # I of the C1 major scale
    $got = $obj->generate('C', 4);
    is $got->[0], $expect, 'tonic';

    $got = $obj->generate('C', 1);
    is $got->[0], $expect, 'tonic';

    $obj = new_ok $module => [
        verbose => VERBOSE,
        modal   => 1,
    ];
    $expect = 46; # = A#2
    $got = $obj->generate('Dm7', 99); # An A# would surely not turn up in 99 rolls! Right? Uhh...
    $got = grep { $_ != $expect } @$got;
    ok $got, 'modal';

    $obj = new_ok $module => [
        verbose     => VERBOSE,
        modal       => 1,
        chord_notes => 0,
    ];
    $expect = 44; # = G#2
    $got = $obj->generate('Dm7b5', 99); # A G# would surely not...
    $got = grep { $_ != $expect } @$got;
    ok $got, 'chord_notes';
};

subtest wrap => sub {
    # set the octave at the wrap!
    my $obj = new_ok $module => [
        verbose   => VERBOSE,
        octave    => 3,
        wrap      => 'C3',
        modal     => 1,
        keycenter => 'C',
    ];

    my $got = $obj->generate('C', 4);
    my $expect = 4;
    $got = grep { $_ <= 48 } @$got;
    is $got, $expect, 'wrap';
};

subtest positions => sub {
    my $obj = new_ok $module => [
        verbose     => VERBOSE,
        chord_notes => 0,
        positions   => { major => [1], minor => [1] },
    ];
    my $expect = [26,26,26,26];
    my $got = $obj->generate('C', 4);
    is_deeply $got, $expect, 'positions';
};

done_testing();
