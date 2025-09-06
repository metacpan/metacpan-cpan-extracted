# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl t/00-load.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Module::Case') };
BEGIN { use_ok('Cwd') };
BEGIN { use_ok('IO::Socket') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
