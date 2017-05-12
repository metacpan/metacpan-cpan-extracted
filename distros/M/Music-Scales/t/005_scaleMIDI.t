# -*- perl -*-

# t/005_scaleMIDI.t - check get_scale_MIDI is ok

use Test::Simple tests => 3;
use Music::Scales;

ok(join(" ",get_scale_MIDI('C',-1)) eq "0 2 4 5 7 9 11");
ok(join(" ",get_scale_MIDI('Bb',4,"dorian")) eq "70 72 73 75 77 79 80");
ok(join(" ",get_scale_MIDI('Ab',5,"locrian",1)) eq "90 88 86 85 83 81 80");

