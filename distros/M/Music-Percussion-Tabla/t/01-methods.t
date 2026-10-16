#!/usr/bin/env perl
use v5.36;

use Test::More;
use File::Temp qw(tempdir);
use List::Util qw(any);
use MIDI::Opus ();
use MIDI::Util qw(dura_size ticks);

use_ok 'Music::Percussion::Tabla';

# MIDI::Simple note events look like:
#   [ 'note', $start_ticks, $duration_ticks, $channel, $note_number, $velocity ]
sub notes_of ($obj) {
    return grep { $_->[0] eq 'note' } $obj->score->Score;
}

sub ticks_for ($obj, $dura) {
    return ticks($obj->score) * dura_size($dura);
}

sub new_tabla (%args) {
    return Music::Percussion::Tabla->new(%args);
}

sub is_one_of ($patch, $pool) {
    return (any { $_ == $patch } @$pool) ? 1 : 0;
}

subtest defaults => sub {
    my $obj = new_ok 'Music::Percussion::Tabla';
    is $obj->verbose, 0, 'verbose';
    is $obj->channel, 0, 'channel';
    isa_ok $obj->score, 'MIDI::Simple';
    isa_ok $obj, 'MIDI::Drummer::Tiny';
    like $obj->soundfont, qr{/Tabla\.sf2\z}, 'soundfont';
    is ref $obj->patches, 'HASH', 'patches';
    is scalar(notes_of($obj)), 0, 'no notes before any strikes';
};

subtest patches => sub {
    my $patches = new_tabla()->patches;

    # Every single-strike bol listed in the POD should exist
    for my $bol (qw(ge ke na te tu ti tin sur)) {
        ok exists $patches->{$bol}, "documented bol '$bol' is defined";
    }
    for my $bol (qw(dha dhin dhit dhun)) {
        ok exists $patches->{$bol}, "documented double bol '$bol' is defined";
    }

    # Double-strike bols hold bol names; single-strike bols hold numbers
    my (%single, %double);
    for my $bol (keys %$patches) {
        if (grep { /[a-z]/ } $patches->{$bol}->@*) { $double{$bol} = $patches->{$bol} }
        else                                       { $single{$bol} = $patches->{$bol} }
    }

    for my $bol (sort keys %single) {
        ok scalar $single{$bol}->@*, "$bol: has at least one patch";
        my @bad = grep { !/\A\d+\z/ || $_ > 127 } $single{$bol}->@*;
        is_deeply \@bad, [], "$bol: patches are MIDI note numbers";
    }

    for my $bol (sort keys %double) {
        is scalar $double{$bol}->@*, 2, "$bol: has exactly two members";
        for my $member ($double{$bol}->@*) {
            ok exists $single{$member},
                "$bol: member '$member' is a defined single-strike bol";
        }
    }
};

subtest 'strike: single bols' => sub {
    my $patches = new_tabla()->patches;

    for my $bol (qw(ge ke na te tu ti tin sur)) {
        my $obj  = new_tabla();
        my $dura = $obj->eighth;
        my $got  = $obj->strike($bol, $dura);

        is ref $got, 'ARRAY', "$bol: returns an arrayref";
        is scalar @$got, 1, "$bol: one strike";
        is $got->[0][0], $dura, "$bol: returned duration";
        is scalar $got->[0]->@*, 2, "$bol: duration plus one patch";

        my $patch = $got->[0][1];
        ok is_one_of($patch, $patches->{$bol}), "$bol: returned patch belongs to the bol";

        my @notes = notes_of($obj);
        is scalar @notes, 1, "$bol: one note in the score";
        is $notes[0][4], $patch, "$bol: score note matches the returned patch";
        is $notes[0][2], ticks_for($obj, $dura), "$bol: duration in ticks";
    }

    # 'tu' has a single patch, so it is deterministic
    my $obj = new_tabla();
    is $obj->strike('tu')->[0][1], 60, 'tu is note 60';
};

subtest 'strike: defaults and randomness' => sub {
    my $obj = new_tabla();
    $obj->strike('na');
    my ($note) = notes_of($obj);
    is $note->[2], ticks_for($obj, $obj->quarter), 'default duration is a quarter note';
    is $note->[3], $obj->channel, 'note is on the object channel';

    # With 200 strikes the chance of missing one of 5 patches is ~1e-19
    my %seen;
    $seen{ $obj->strike('ge')->[0][1] }++ for 1 .. 200;
    is_deeply [ sort { $a <=> $b } keys %seen ],
        [ sort { $a <=> $b } $obj->patches->{ge}->@* ],
        'every patch of a bol gets used';
};

subtest 'strike: double bols' => sub {
    my $patches = new_tabla()->patches;

    for my $bol (qw(dha dhin dhit dhun)) {
        my $obj = new_tabla();
        my ($baya_bol, $daya_bol) = $patches->{$bol}->@*;

        my $got = eval { $obj->strike($bol, $obj->eighth) };
        if (!ok $got, "$bol: strike lives") { diag $@; next }

        is scalar @$got, 1, "$bol: one strike spec";
        is scalar $got->[0]->@*, 3, "$bol: duration plus two patches";
        my ($baya, $daya) = $got->[0]->@[1, 2];

        ok is_one_of($baya, $patches->{$baya_bol}), "$bol: baya patch comes from '$baya_bol'";
        ok is_one_of($daya, $patches->{$daya_bol}), "$bol: daya patch comes from '$daya_bol'";

        my @notes = notes_of($obj);
        is scalar @notes, 2, "$bol: two notes in the score";
        is $notes[0][1], $notes[1][1], "$bol: both drums sound at the same time";
        is_deeply [ map { $_->[4] } @notes ], [ $baya, $daya ],
            "$bol: score matches the returned spec";
    }
};

subtest 'strike: arrayref of bols' => sub {
    my $patches = new_tabla()->patches;

    my $obj  = new_tabla();
    my $dura = $obj->eighth;
    my $got  = $obj->strike([qw(ge ke)], $dura);

    is scalar @$got, 1, 'one spec for the pair';
    is scalar $got->[0]->@*, 3, 'duration plus two patches';
    ok is_one_of($got->[0][1], $patches->{ge}), 'first patch comes from ge';
    ok is_one_of($got->[0][2], $patches->{ke}), 'second patch comes from ke';

    my @notes = notes_of($obj);
    is scalar @notes, 2, 'two notes in the score';
    is $notes[0][1], $notes[1][1], 'members sound together';
    is $notes[0][2], ticks_for($obj, $dura), 'duration in ticks';

    # A double bol inside the pair expands to its members
    my $obj2 = new_tabla();
    $obj2->strike([qw(dha ke)]);
    my @notes2 = notes_of($obj2);
    is scalar @notes2, 3, 'dha + ke is three notes';
    is scalar(keys %{ { map { $_->[1] => 1 } @notes2 } }), 1, 'all at the same time';
};

subtest 'strike: unknown bol' => sub {
    for my $bol ('nonesuch', [qw(ge nonesuch)]) {
        my $label = ref $bol ? 'pair' : 'single';
        my $obj   = new_tabla();
        my $lived = eval { $obj->strike($bol); 1 };
        my $err   = $@;
        ok !$lived, "$label: dies";
        like $err, qr/nonesuch/, "$label: message names the bol";
        is scalar(notes_of($obj)), 0, "$label: nothing was written to the score";
    }
};

subtest write => sub {
    my $file = tempdir(CLEANUP => 1) . '/tabla.mid';
    my $obj  = new_tabla(file => $file);
    $obj->strike('tu') for 1 .. 2; # deterministic: note 60

    $obj->write;
    ok -s $file, 'MIDI file was written';

    # Read it back and check the notes survived the round trip
    my $opus = MIDI::Opus->new({ from_file => $file });
    my @on = grep { $_->[0] eq 'note_on' && $_->[4] > 0 }
             map { $_->events } $opus->tracks;
    is_deeply [ map { $_->[3] } @on ], [ 60, 60 ], 'note-on events in the file';
};

done_testing();