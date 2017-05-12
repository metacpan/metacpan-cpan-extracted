## WOW!  FIXME!  XXX!  Something definitely needs to be done here.  
## I'll have to whip up a sample stream and make it work.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

warn "THIS MODULE IS STILL VERY BETA -- THERE IS NO REAL TEST.\n";
warn "USE AT YOUR OWN RISK.\n";

use Test::More tests => 1;
BEGIN { use_ok('POE::Component::Audio::Mad') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

