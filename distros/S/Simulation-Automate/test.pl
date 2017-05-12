# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Simulation::Automate;
system("ln -s ./blib/lib/Simulation .");
chdir "eg";
ok(&synsim("test.data"));
system("rm -f ../Simulation")

