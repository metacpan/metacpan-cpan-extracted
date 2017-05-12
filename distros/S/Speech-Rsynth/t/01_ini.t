# -*- Mode: Perl -*-
# t/01_ini.t; just test load the module by using it

use vars qw($TEST_DIR);
$TEST_DIR = './t';
#use lib qw(../blib/lib); $TEST_DIR = '.'; # for debugging

# change 'tests => 1' to 'tests => last_test_to_print';
use Test;
BEGIN { plan tests => 1 };
use Speech::Rsynth;
ok(1); # If we made it this far, we're ok.

print "\n";
# end of t/01_ini.t
