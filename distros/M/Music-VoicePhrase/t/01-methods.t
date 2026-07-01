#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use List::Util qw(any);
# use Data::Dumper::Compact qw(ddc);

use_ok 'Music::VoicePhrase';

subtest defaults => sub {
    my $obj = new_ok 'Music::VoicePhrase';
    is $obj->base, 'C', 'base';
    is $obj->scale, 'major', 'scale';
    is $obj->octave, 0, 'octave';
    is $obj->patch, 0, 'patch';
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
        pitches   => [qw(60 64 67)],
        motif_num => 20,
    ];
    my $same = 0;
    for my $voice ($obj->voices->@*) {
        $same = any { $voice == $_ } $obj->pitches->@*;
    }
    ok $same, 'pitches';
};

done_testing();
