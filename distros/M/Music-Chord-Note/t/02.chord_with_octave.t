use strict;
use warnings;
use Test::More;

use Music::Chord::Note;

my $cn = Music::Chord::Note->new;

{
    my @chord = $cn->chord_with_octave('CM7');
    is "@chord", 'C4 E4 G4 B4';
}

{
    my @chord = $cn->chord_with_octave('CM7', 5);
    is "@chord", 'C5 E5 G5 B5';
}

{
    my @chord = $cn->chord_with_octave('B', 6);
    is "@chord", 'B6 D#7 F#7';
}

{
    eval { $cn->chord_with_octave('C', -3); };
    like($@, qr/octave should be integer between -2 and 9/);
}

{
    eval { $cn->chord_with_octave('C', 10); };
    like($@, qr/octave should be integer between -2 and 9/);
}

done_testing();
