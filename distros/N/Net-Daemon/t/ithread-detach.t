# -*- perl -*-
#
# Test that ChildFunc detaches threads to prevent memory leaks
# from leftover thread mappings (GitHub issue #12).

require 5.004;
use strict;
use warnings;

use Config;

if ( !$Config{useithreads} ) {
    print "1..0 # SKIP This test requires a perl with working ithreads.\n";
    exit 0;
}
require threads;

print "1..2\n";

use Net::Daemon ();

# Create a minimal daemon object in ithreads mode
my $daemon = bless {
    'mode'  => 'ithreads',
    'debug' => 0,
}, 'Net::Daemon';

# Track whether the method was called
my $method_called = 0;

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

printf "%s 1 - thread ran successfully\n", $done ? "ok" : "not ok";

# After ChildFunc, there should be no joinable threads
# (detached threads don't appear in the joinable list)
my @joinable = threads->list(threads::joinable());
my @running  = threads->list(threads::running());
my @all      = threads->list(threads::all());

# Detached threads are excluded from threads->list(threads::all)
# so there should be no threads left to manage
my $no_joinable = ( scalar(@joinable) == 0 );
printf "%s 2 - no joinable threads remain (thread was detached)\n",
    $no_joinable ? "ok" : "not ok";

if ( !$no_joinable ) {
    print STDERR "# joinable: " . scalar(@joinable) . ", running: " . scalar(@running) . ", all: " . scalar(@all) . "\n";
    # Clean up any un-detached threads to avoid warnings
    $_->join() for @joinable;
}
