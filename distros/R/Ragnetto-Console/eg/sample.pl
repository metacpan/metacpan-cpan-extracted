use strict;
use warnings;
use Ragnetto::Console qw(:all);

clear();
title("Ragnetto::Console - Sample");
cursor('OFF');

my $w = width();
my $h = height();

position(1, 2);

print "Testing Colors (0-15): ";
for my $i (0..15) {
    backcolor($i);
    print "  ";
}

reset();

write("Terminal detected: ${w}x${h}", "CYAN", "BLACK", 1, 4);

position(1, 6);

print "Testing Caret Shapes (Cycle 1-6): ";

for my $s (1..6) {
    caret($s);

    select(undef, undef, undef, 0.2);
}

caret('BLOCK_STEADY');

print "Done.";

position(1, 10);

write(" STEP 1: Press 'G' (Silent getkey) ", "WHITE", "BLUE");

my $k1 = getkey();

position(1, 11);

if (uc($k1) eq 'G') {
    write(" SUCCESS: You pressed G ", "GREEN", "BLACK");
}
else {
    write(" FAIL: Received '$k1' instead of G ", "RED", "WHITE");
}

position(1, 13);

print "STEP 2: Type something (Visual putkey): ";

my $k2 = putkey();

position(1, 16);

write(" TEST COMPLETED. Press any key to exit. ", "BLACK", "GRAY");

getkey();

reset();

clear();

cursor('ON');

print "System restored. Ready for CPAN!\n";
