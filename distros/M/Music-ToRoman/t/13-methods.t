#!/usr/bin/env perl

# Test the modes

use strict;
use warnings;
no warnings 'qw';

use Test::More;

use_ok 'Music::ToRoman';

my @notes = qw/ C D  E   F  G A  B /;
my @modes = qw/ I ii iii IV V vi vii /;
my %equiv;
@equiv{ map { lc } @modes } = 1 .. @modes;
@equiv{ map { uc } @modes } = 1 .. @modes;

my $i = 0;
for my $scale_note ( @notes ) {
    diag "scale_note: $scale_note";

    my $j = 0;
    for my $scale_name (qw/ ionian dorian phrygian lydian mixolydian aeolian locrian /) {
        if ( $i != $j ) {
            $j++;
            next;
        }

        my $mtr = Music::ToRoman->new( #verbose=>1,
            scale_note  => $scale_note,
            scale_name  => $scale_name,
            chords      => 0,
        );
        isa_ok $mtr, 'Music::ToRoman';

#        diag "\t@modes";
        diag "\tscale_name: $scale_name";

        for my $note ( @notes ) {
            my $roman = $mtr->parse($note);
            my $mode = $modes[ $equiv{$roman} - 1 ];
#            diag "\t\t$note => $roman ($mode)";
            my $roman_case = ( $roman =~ /^[A-Z]+$/ ) ? 'UPPER' : ( $roman =~ /^[a-z]+$/ ) ? 'lower' : '?';
            my $mode_case = ( $mode =~ /^[A-Z]+$/ ) ? 'UPPER' : ( $mode =~ /^[a-z]+$/ ) ? 'lower' : '?';
            isnt $roman_case, '?', 'known case';
            is $roman_case, $mode_case, 'cases match';
        }

        push @modes, shift @modes;

        $j++;
    }

    $i++;
}

done_testing();
