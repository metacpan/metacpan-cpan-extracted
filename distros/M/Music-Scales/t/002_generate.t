# -*- perl -*-

# t/002_generate.t - check scales are ok

use Test::Simple tests => 7;
use Music::Scales;

ok(join(" ",get_scale_notes('C',1)) eq "C D E F G A B");
ok(join(" ",get_scale_notes('D',1)) eq "D E F# G A B C#");
ok(join(" ",get_scale_notes('Eb',1)) eq "Eb F G Ab Bb C D");
ok(join(" ",get_scale_nums(1)) eq "0 2 4 5 7 9 11");
ok(join(" ",get_scale_nums(30)) eq "0 3 5 7 10");
ok(join(" ",get_scale_notes('C',"chromatic")) eq "C C# D D# E F F# G G# A A# B");
ok(join(" ",get_scale_notes('C',"chromatic",1)) eq "C B Bb A Ab G Gb F E Eb D Db");



