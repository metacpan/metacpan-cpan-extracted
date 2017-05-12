# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Runops-Recorder.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use File::Path qw(remove_tree);

BEGIN { 
    remove_tree("test-recording");
    use_ok('Runops::Recorder', qw(test-recording -nostore -bs=512)) 
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub foo {
    1;
    
    die "foo";
}

ok(!-e "test-recording/foo.data");

eval {
    foo();
};

Runops::Recorder::dump("foo");

ok(-e "test-recording/foo.data");