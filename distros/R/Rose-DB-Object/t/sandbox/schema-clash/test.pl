#!/usr/bin/perl

use FindBin qw($Bin);

chdir($Bin) or die "Could not chdir($Bin) - $!";

use lib "$Bin/../../../lib";
use lib "$Bin/../../../../Rose-DB/lib";
use lib "$Bin/lib";

system(qw(/usr/bin/perl -I ../../../lib -I ../../../../Rose-DB/lib -I lib t/one.t));
system(qw(/usr/bin/perl -I ../../../lib -I ../../../../Rose-DB/lib -I lib t/two.t));
