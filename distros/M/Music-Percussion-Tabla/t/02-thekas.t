#!/usr/bin/env perl
use v5.36;

use Test::More;
use List::Util qw(any);
use MIDI::Util qw(dura_size ticks);

use_ok 'Music::Percussion::Tabla';

my @TIRA = qw(ti na ke te); # tirakita

# The expected bol sequence of each theka, with tirakita expanded
my %THEKA = (
    teentaal => [
        (qw(dha dhin dhin dha)) x 2,
        qw(dha tin tin te te dhin dhin dha),
    ],
    keherawa    => [qw(dha ge na tin na ke dhin na)],
    jhaptaal    => [qw(dhin na dhin dhin na tin na dhin dhin na)],
    dadra       => [qw(dha dhin na dha ti na)],
    rupaktaal   => [qw(tin tin na dhin na dhin na)],
    ektaal      => [
        qw(dhin dhin dha), @TIRA,
        qw(ti na ke te dha), @TIRA,
        qw(dhin na),
    ],
    arachartaal => [
        'dhin', @TIRA,
        qw(dhit na ti na ke te), @TIRA,
        qw(dhit na dhit dhit na),
    ],
    tirakita    => [@TIRA],
);

# Beat counts from the POD, at one quarter note per beat
my %BEATS = (
    teentaal    => 16,
    keherawa    => 8,
    jhaptaal    => 10,
    dadra       => 6,
    rupaktaal   => 7,
    ektaal      => 12,
    arachartaal => 14,
    tirakita    => 4,
);

sub notes_of ($obj) {
    return grep { $_->[0] eq 'note' } $obj->score->Score;
}

sub ticks_for ($obj, $dura) {
    return ticks($obj->score) * dura_size($dura);
}

# Group notes that start together: [ [note, note], [note], ... ] in time order
sub chords_of ($obj) {
    my (@order, %by_start);
    for my $n (notes_of($obj)) {
        push @order, $n->[1] unless $by_start{ $n->[1] };
        push $by_start{ $n->[1] }->@*, $n->[4];
    }
    return [ map { $by_start{$_} } @order ];
}

# Does this chord of MIDI notes realize $bol?  A double bol is its two
# members in order (baya, daya); a single bol is one of its patches.
sub chord_fits ($patches, $bol, $chord) {
    my $def     = $patches->{$bol};
    my @members = (grep { /[a-z]/ } @$def) ? @$def : ($bol);
    return 0 unless @$chord == @members;
    for my $i (0 .. $#members) {
        my $pool = $patches->{ $members[$i] };
        return 0 unless any { $_ == $chord->[$i] } @$pool;
    }
    return 1;
}

# Beats between the first and last strike, counting the last strike itself.
# (Every theka ends on a full-length strike.)
sub beats_spanned ($obj, $dura) {
    my @notes = notes_of($obj);
    return ($notes[-1][1] - $notes[0][1]) / ticks_for($obj, $dura) + 1;
}

for my $theka (sort keys %THEKA) {
    subtest $theka => sub {
        for my $name (qw(quarter eighth)) {
            my $obj  = Music::Percussion::Tabla->new;
            my $dura = $obj->$name;
            my $got  = eval { $obj->$theka($dura) };
            if (!ok $got, "$name: lives") { diag $@; next }

            is ref $got, 'ARRAY', "$name: returns the strikes";
            is beats_spanned($obj, $dura), $BEATS{$theka}, "$name: lasts $BEATS{$theka} beats";

            my @starts = map { $_->[1] } notes_of($obj);
            is_deeply \@starts, [ sort { $a <=> $b } @starts ], "$name: notes are in time order";
        }

        # The bols themselves
        my $obj      = Music::Percussion::Tabla->new;
        my $patches  = $obj->patches;
        my @expected = $THEKA{$theka}->@*;
        $obj->$theka;
        my $chords = chords_of($obj);

        is scalar @$chords, scalar @expected, 'number of strikes';
        my @wrong = grep { !chord_fits($patches, $expected[$_], $chords->[$_]) }
                    0 .. $#expected;
        is_deeply \@wrong, [], 'every strike is the expected bol'
            or diag "wrong positions: @wrong (expected @expected[@wrong])";

        # Default duration is a quarter note
        is beats_spanned($obj, $obj->quarter), $BEATS{$theka}, 'default duration is a quarter note';
    };
}

subtest 'tirakita subdivisions' => sub {
    my $obj = Music::Percussion::Tabla->new;
    $obj->tirakita($obj->sixteenth);
    my @starts = map { $_->[1] } notes_of($obj);
    is scalar @starts, 4, 'four notes';

    my $step = ticks_for($obj, $obj->sixteenth);
    is_deeply [ map { $_ - $starts[0] } @starts ],
        [ 0, $step, 2 * $step, 3 * $step ],
        'evenly spaced sixteenths';
};

subtest 'ektaal and arachartaal subdivide a beat' => sub {
    # The tirakita inside these thekas fills exactly one beat
    for my $theka (qw(ektaal arachartaal)) {
        my $obj = Music::Percussion::Tabla->new;
        $obj->$theka;

        my %length;
        $length{ $_->[2] }++ for notes_of($obj);
        my $beat = ticks_for($obj, $obj->quarter);
        is $length{ $beat / 4 }, 8, "$theka: eight sixteenth-note strikes (two tirakitas)";
    }
};

done_testing();