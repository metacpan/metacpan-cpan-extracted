# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POE-Devel-Profiler.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use_ok( 'POE::Devel::Profiler::Parser' );
use_ok( 'POE::Devel::Profiler::Visualizer::BasicSummary' );
use_ok( 'POE::Devel::Profiler::Visualizer::BasicGraphViz' );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

