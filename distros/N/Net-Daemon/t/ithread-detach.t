# -*- perl -*-
#
# Test that ChildFunc detaches threads to prevent memory leaks
# from leftover thread mappings (GitHub issue #12).

require 5.004;
use strict;
use warnings;

use Config;
use Test::More;

if ( !$Config{useithreads} ) {
    plan skip_all => 'This test requires a perl with working ithreads.';
}
if ( $] < 5.010 ) {
    print "1..0 # SKIP Perl $] ithreads global destruction is unstable before 5.10\n";
    exit 0;
}
require threads;

plan tests => 2;

use Net::Daemon ();

# Create a minimal daemon object in ithreads mode
my $daemon = bless {
    'mode'  => 'ithreads',
    'debug' => 0,
}, 'Net::Daemon';

# Define a simple method that sets a shared flag
my $done : shared = 0;

no strict 'refs';
*Net::Daemon::_test_child = sub {
    $done = 1;
};
use strict 'refs';

# Call ChildFunc which should create and detach a thread
$daemon->ChildFunc('_test_child');

# Give the thread time to run
for (1..50) {
    last if $done;
    select(undef, undef, undef, 0.1);
}

ok( $done, 'thread ran successfully' );

# After ChildFunc, there should be no joinable threads
# (detached threads don't appear in the joinable list)
my @joinable = threads->list(threads::joinable());

ok( scalar(@joinable) == 0, 'no joinable threads remain (thread was detached)' );

if ( scalar(@joinable) ) {
    diag "joinable: " . scalar(@joinable)
       . ", running: " . scalar(threads->list(threads::running()))
       . ", all: " . scalar(threads->list(threads::all()));
    # Clean up any un-detached threads to avoid warnings
    $_->join() for @joinable;
}
