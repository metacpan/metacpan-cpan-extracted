use strict;

use Test::More tests => 36;

use Music::Chord::Note;

my $cn = Music::Chord::Note->new();
isa_ok($cn, 'Music::Chord::Note', 'new');


eval { my @fail = $cn->chord(''); };
like($@, qr/No CHORD_NAME!/, "No CHORD_NAME");

eval { my @fail = $cn->chord('H'); };
like($@, qr/unknown chord H at/, "unknown chord1 H");

eval { my @fail = $cn->chord('Hm7'); };
like($@, qr/unknown chord Hm7 at/, "unknown chord2 Hm7");

eval { my @fail = $cn->chord('hoge'); };
like($@, qr/unknown chord hoge at/, "unknown chord4 hoge");

eval { my @fail = $cn->chord('Cm2'); };
like($@, qr/undefined kind of chord m2\(Cm2\) at/, "undefined kind of chord");


my %testchords = (
    'C'     => 'C E G',
    'C6'    => 'C E G A',
    'Csus4' => 'C F G',
    'C7'    => 'C E G A#',
    'CM7'   => 'C E G B',
    'Cm'    => 'C D# G',
    'Cm7'   => 'C D# G A#',
    'CmM7'  => 'C D# G B',
    'Cm13'  => 'C D# G A# D F A',
    'Csus4' => 'C F G',
    'Caug'  => 'C E G#',
    'Cdim'  => 'C D# F#',
    'Cadd2' => 'C D E G',

    'C#'     => 'C# F G#',
    'F'      => 'F A C',
    'B'      => 'B D# F#',
    'Bm13'   => 'B D F# A C# E G#',
);

foreach my $c (sort keys %testchords){
    my @Chord = $cn->chord($c);
    is($testchords{$c}, "@Chord", $c.' -> '.$testchords{$c});
}


eval { my $no_note = $cn->scale(''); };
like($@, qr/wrong note/, "No Note");

eval { my $wrong_note = $cn->scale('H'); };
like($@, qr/wrong note/, "Wrong Note H");

eval { my $wrong_note = $cn->scale('C+'); };
like($@, qr/wrong note/, "Wrong Note C+");

eval { my $wrong_note = $cn->scale('D-'); };
like($@, qr/wrong note/, "Wrong Note D-");

my $sv = $cn->scale('C');
is($sv, 0, 'Scalic Value C');

my $sv1 = $cn->scale('A');
is($sv1, 9, 'Scalic Value A');

my $sv2 = $cn->scale('A#');
is($sv2, 10, 'Scalic Value A#');

my $sv3 = $cn->scale('Eb');
is($sv3, 3, 'Scalic Value Eb');

my $sv4 = $cn->scale('gb');
is($sv4, 6, 'Scalic Value gb');


eval { my @fail = $cn->chord_num('H'); };
like($@, qr/undefined kind of chord/, "undefined kind of chord:chord_num");

my @Kind = $cn->chord_num('');
is("0 4 7", "@Kind", 'nothing:chord_num');

my @Kind2 = $cn->chord_num('base');
is("0 4 7", "@Kind2", 'base:chord_num');

my @Kind3 = $cn->chord_num('m7');
is("0 3 7 10", "@Kind3", 'chord_num:m7');


my $all_chords_list = $cn->all_chords_list;
is(64, $#{$all_chords_list}, 'number of all chords');
