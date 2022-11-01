# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Terminal-Control.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6;

BEGIN { use_ok('Terminal::Identify') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

require_ok( 'POSIX' );

ok(Terminal::Identify::whichterminalami());
ok(Terminal::Identify::whichterminalami("PROC"));
ok(Terminal::Identify::whichterminalami("PATH"));
ok(Terminal::Identify::whichterminalami("FTN"));
