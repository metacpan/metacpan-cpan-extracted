# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Snail-CSV.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Snail::CSV') };
require_ok('Snail::CSV');

use_ok('Text::CSV_XS');
use_ok('IO::File');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

