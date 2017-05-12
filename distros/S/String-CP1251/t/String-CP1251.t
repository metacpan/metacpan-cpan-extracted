# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl String-CP1251.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('String::CP1251') };

cmp_ok(String::CP1251::lc(chr(192)), 'eq', chr(224), 'CAPITAL A -> a');
# TODO: entire 2 alphabets
# uc
# vars - make sure that var is not rewritten in place


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

