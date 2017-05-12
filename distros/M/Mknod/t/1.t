# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Mknod') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

if(Mknod::mknod('_tztnod', Mknod::S_IFIFO|0644)) {
    ok(1, 'fifo');
    unlink('_tztnod');
}
else {
    ok(0, 'fifo');
}

    
