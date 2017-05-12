use strict;
use warnings;

#
# "to codulate" (making a CODE ref of something) is an invention of mst, with
# discussion with LeoNerd, ilmari, and myself at YAPC::EU::2014 (Sofia)
#
# adjective:   codulable
# action noun: codulation


# Due to bug 122607, codulation is not so useful in practice: codulating from
# our Term::Chrome constants does not even compile :(
# https://rt.perl.org/Ticket/Display.html?id=122607
# Fortunately, Father Chrysostomos fixed the issue.

use Test::Is 'perl 5.21.4';
use Test::More tests => 3;

use Term::Chrome;

my $YellowBlue = Blue / Yellow + Reset + Reverse;
is($YellowBlue->("Text"),
    "\e[;7;34;43mText\e[39;49;27m",
    "(Blue / Yellow + Reset + Reverse) but using code deref with a variable");

is(&{Blue / Yellow + Reset + Reverse}("Text"),
    "\e[;7;34;43mText\e[39;49;27m",
    "(Blue / Yellow + Reset + Reverse) but using code deref with &");

is((Blue / Yellow + Reset + Reverse)->("Text"),
    "\e[;7;34;43mText\e[39;49;27m",
    "(Blue / Yellow + Reset + Reverse) but using code deref with ->, directly (perl RT 122607)");
