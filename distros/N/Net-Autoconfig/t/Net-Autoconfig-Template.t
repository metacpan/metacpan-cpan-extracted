# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Autoconfig.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 3;
BEGIN { use_ok('Net::Autoconfig::Template') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#
#


ok(Net::Autoconfig::Template->new(), "Testing for empty Device object creation"); 
is(ref(Net::Autoconfig::Template->new()), 'Net::Autoconfig::Template', "Testing for empty Device object creation"); 

my $template = Net::Autoconfig::Template->new();


