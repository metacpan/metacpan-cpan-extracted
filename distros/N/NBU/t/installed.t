# -*- perl -*-

require 5.004;
use strict;

use vars qw($loaded);

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1: NetBackup not installed\n" unless $loaded;}

use NBU;
$loaded = 1;
print "ok 1\n";
