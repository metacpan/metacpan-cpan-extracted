# -*- perl -*-

# t/004_scalePDL.t - check scale_to_PDL is ok

use Test::Simple tests => 4;
use Music::Scales;

ok(join(" ",get_scale_PDL('G',4,'hm')) eq "g4 a4 bf4 c5 d5 ef5 fs5");
ok(join(" ",get_scale_PDL('C#',2,'30')) eq "cs2 e2 fs2 gs2 b2");
ok(join(" ",get_scale_PDL('F#',5,'30')) eq "fs5 a5 b5 cs6 e6");
ok(join(" ",get_scale_PDL('F#',5,'30',1)) eq "fs6 e6 cs6 b5 a5");

