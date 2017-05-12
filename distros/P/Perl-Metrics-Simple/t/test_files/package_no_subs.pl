#!/usr/bin/perl
###############################################################################

package Hello::Dolly;

use strict;
use warnings;

START:
print "Hello world.\n";
print "I have a package.\n";
print "I have no subs.\n";

for ( 1..5 ) {
    print "$_\n";
}
goto START;

exit;
