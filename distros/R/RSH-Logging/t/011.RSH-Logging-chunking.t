# 010.RSH-Logging.t - unit test

# If you have any questions about this software,
# or need to report a bug, please contact me.
# 
# Matt Luker
# Port Angeles, WA
# mluker@rshtech.com
# 
# TTGOG

use strict;
use warnings;

use Test::More tests => 48;

BEGIN { use_ok('RSH::Logging') };

use RSH::Logging qw(start_event_tracking stop_event_tracking start_event stop_event get_event_tracking_results print_event_tracking_results);

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( { level   => $DEBUG, layout   => '%p %F{1}:%L, %M: %m%n'  } );
our $logger = get_logger(__PACKAGE__);
use IO::File;

my $test_name = undef;
my $test_count = 0;

$test_name = "print_event_tracking_results (logger, chunking)";
$test_count = 1;
eval {
    start_event_tracking($logger, "foo");
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    start_event("sub1a");
    pass("$test_name - $test_count");
    $test_count++;
    start_event("sub2a");
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;
    start_event("sub2b");
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;
    stop_event_tracking();
    ok((defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    print_event_tracking_results($logger, 1);
    pass("$test_name - $test_count");
    $test_count++;
};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 9; $i++) {
        fail("$test_name - $i");
    }
}

$test_name = "print_event_tracking_results (\$fh, chunking)";
$test_count = 1;
eval {
    start_event_tracking($logger, "foo");
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    start_event("sub1a");
    pass("$test_name - $test_count");
    $test_count++;
    start_event("sub2a");
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;
    start_event("sub2b");
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;
    stop_event_tracking();
    ok((defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    print_event_tracking_results((new IO::File ">&STDOUT"), 1);
    pass("$test_name - $test_count");
    $test_count++;
};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 9; $i++) {
        fail("$test_name - $i");
    }
}

$test_name = "print_event_tracking_results (filename, chunking)";
$test_count = 1;
eval {
    start_event_tracking($logger, "foo");
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    start_event("sub1a");
    pass("$test_name - $test_count");
    $test_count++;
    start_event("sub2a");
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;
    start_event("sub2b");
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;
    stop_event_tracking();
    ok((defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    print_event_tracking_results((new IO::File "&STDOUT"), 1);
    pass("$test_name - $test_count");
    $test_count++;
};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 9; $i++) {
        fail("$test_name - $i");
    }
}


$test_name = "sequential start_event_tracking/sub-events/stop_event_tracking (auto-chunk)";
$test_count = 1;
$RSH::Logging::AUTO_CHUNK_LIMIT = 10;
eval {
    start_event_tracking($logger, "foo");
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    start_event("sub1a");
    pass("$test_name - $test_count");
    $test_count++;
    start_event("sub2a");
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;
    start_event("sub2b");
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;

    stop_event();
    pass("$test_name - $test_count");
    $test_count++;

    for (my $i = 0; $i < 5; $i++) {
        start_event("sub$i");
        stop_event();
    }
    pass("$test_name - $test_count (bulk)");
    $test_count++;

    stop_event_tracking();
    ok((defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    print_event_tracking_results($logger);
    pass("$test_name - $test_count");
    $test_count++;

    start_event_tracking($logger, "foo");
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    start_event("sub1a");
    pass("$test_name - $test_count");
    $test_count++;
    start_event("sub2a");
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;
    start_event("sub2b");
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;

    stop_event();
    pass("$test_name - $test_count");
    $test_count++;

    for (my $i = 0; $i < 25; $i++) {
        start_event("sub$i");
        stop_event();
    }
    pass("$test_name - $test_count (bulk)");
    $test_count++;

    stop_event_tracking();
    ok((defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    print_event_tracking_results($logger);
    pass("$test_name - $test_count");
    $test_count++;

};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 18; $i++) {
        fail("$test_name - $i");
    }
}

$RSH::Logging::AUTO_CHUNK_LIMIT = -1;

exit 0;

# ------------------------------------------------------------------------------
#  $Log$
# ------------------------------------------------------------------------------