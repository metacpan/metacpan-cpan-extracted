##-*- Mode: Perl -*-
my ($last_test,$loaded);

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';

BEGIN { $last_test = 1; $| = 1; print "1..$last_test\n"; }
END   { print "not ok 1  Can't load module\n" unless $loaded; }

use PDL;
use PDL::GA;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.
