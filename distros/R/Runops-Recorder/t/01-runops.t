# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Runops-Recorder.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
use File::Path qw(remove_tree);

BEGIN { 
    remove_tree("test-recording");
    use_ok('Runops::Recorder', qw(test-recording)) 
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub foo {
    1;
    
    die "foo";
}

eval {
    foo();
};

ok(-e "test-recording/main.data");

is(Runops::Recorder::_get_buffer_size(["-bs=foo"]), Runops::Recorder::DEFAULT_BUFFER_SIZE);
is(Runops::Recorder::_get_buffer_size(["-bs=4G"]), 4_294_967_296);
is(Runops::Recorder::_get_buffer_size(["-bs=4g"]), 4_000_000_000);
is(Runops::Recorder::_get_buffer_size(["-bs=1M"]), 1048576);
is(Runops::Recorder::_get_buffer_size(["-bs=1m"]), 1000000);
is(Runops::Recorder::_get_buffer_size(["-bs=16K"]), 16384);
is(Runops::Recorder::_get_buffer_size(["-bs=16k"]), 16000);
is(Runops::Recorder::_get_buffer_size(["-bs=555"]), 555);
