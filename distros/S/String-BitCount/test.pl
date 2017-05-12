# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::BitCount;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

$st1 = "\x01\x02\x04\x08\x10\x20\x40\x80";
$sh1 = "11111111";
$ct1 = 8;

$st2 = "\x00\x01\x03\x07\x0f\x1f\x3f\x7f\xff";
$sh2 = "012345678";
$ct2 = 36;

$st3 = "\xff\xfe\xfc\xf8\xf0\xe0\xc0\x80\x00";
$sh3 = "876543210";
$ct3 = 36;

$st4 = "\xff\xe7\xc3\x81\x00\x18\x3c\x7e\xff";
$sh4 = "864202468";
$ct4 = 40;

if ($sh1 eq showBitCount $st1) { print "ok 2\n";} else { print "not ok 2\n";}
if ($sh2 eq showBitCount $st2) { print "ok 3\n";} else { print "not ok 3\n";}
if ($sh3 eq showBitCount $st3) { print "ok 4\n";} else { print "not ok 4\n";}

if ($ct1 == BitCount $st1) { print "ok 5\n";} else { print "not ok 5\n";}
if ($ct2 == BitCount $st2) { print "ok 6\n";} else { print "not ok 6\n";}
if ($ct3 == BitCount $st3) { print "ok 7\n";} else { print "not ok 7\n";}

@st = ($st1, $st2, $st3);
$sh = $sh1 . $sh2 . $sh3;
$ct = $ct1 + $ct2 + $ct3;
if ($sh eq showBitCount @st) { print "ok 8\n";} else { print "not ok 8\n";}
if ($ct == BitCount @st) { print "ok 9\n";} else { print "not ok 9\n";}

@sh = showBitCount @st;
if (@sh == 3) { print "ok 10\n";} else { print "not ok 10\n";}
if ("@sh" eq "$sh1 $sh2 $sh3") { print "ok 11\n";} else { print "not ok 11\n";}

# end of test.pl
