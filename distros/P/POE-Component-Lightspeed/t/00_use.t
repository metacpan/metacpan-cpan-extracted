# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 00_use.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use_ok('POE');
use_ok('POE::Component::Lightspeed');
use_ok('POE::Component::Lightspeed::Constants');
#use_ok('POE::Component::Lightspeed::Router');
#use_ok('POE::Component::Lightspeed::Server');
#use_ok('POE::Component::Lightspeed::Client');
#use_ok('POE::Component::Lightspeed::Hack::Kernel');
#use_ok('POE::Component::Lightspeed::Hack::Session');
#use_ok('POE::Component::Lightspeed::Hack::Events');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

