#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use List::Util qw(any);
# use Data::Dumper::Compact qw(ddc);

use_ok 'Music::VoicePhrase';

subtest defaults => sub {
    my $obj = new_ok 'Music::VoicePhrase'; #=> [verbose => 1];
    is $obj->base, 'C', 'base';
    is $obj->scale, 'major', 'scale';
    is $obj->octave, 0, 'octave';
    is $obj->name, 'part', 'name';
    is $obj->patch, 0, 'patch';
    is $obj->gate, 1, 'gate';
    is scalar $obj->pitches->@*, 14, 'pitches';
    is_deeply $obj->intervals, [-3,-2,-1,1,2,3], 'intervals';
    isa_ok $obj->voice, 'Music::VoiceGen';
    is $obj->size, 4, 'size';
    is_deeply $obj->pool, [qw(dhn hn qn)], 'pool';
    is_deeply $obj->weights, [1,2,2], 'weights';
    is_deeply $obj->groups, [0,0,0], 'groups';
    isa_ok $obj->_rhythm, 'Music::Duration::Partition';
    is $obj->motif_num, 4, 'motif_num';
    is scalar $obj->motifs->@*, 4, 'motifs';
    is scalar $obj->voices->@*, 4, 'voices';
    is $obj->verbose, 0, 'verbose';
};

subtest pitches => sub {
    my $obj = new_ok 'Music::VoicePhrase' => [
        pitches      => [qw(60 64 67)],
        pitches_name => 'abc',
        motif_num    => 20,
    ];
    my $got = 0;
    for my $voice ($obj->voices->@*) {
        $got = any { $voice == $_ } $obj->pitches->@*;
    }
    ok $got, 'pitches';
    is $obj->pitches_name, 'abc', 'pitches_name';
};

subtest intervals => sub {
    my $obj = new_ok 'Music::VoicePhrase' => [
        intervals      => [(-4 .. -1), (1 .. 4)],
        intervals_name => 'xyz',
        motif_num      => 20,
    ];
    # TODO not sure how to test intervals, yet. :\
    is $obj->intervals_name, 'xyz', 'intervals_name';
};

subtest size => sub {
    my $obj = new_ok 'Music::VoicePhrase' => [
        size => 5,
    ];
    is $obj->size, 5, 'size';
    $obj = new_ok 'Music::VoicePhrase' => [
        size => 2.5,
    ];
    is $obj->size, 2.5, 'size';
};

done_testing();
