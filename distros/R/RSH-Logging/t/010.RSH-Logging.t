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

use Test::More tests => 107;

BEGIN { use_ok('RSH::Logging') };

use RSH::Logging qw(start_event_tracking stop_event_tracking start_event stop_event get_event_tracking_results print_event_tracking_results);

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( { level   => $DEBUG, layout   => '%p %F{1}:%L, %M: %m%n'  } );
our $logger = get_logger(__PACKAGE__);
use IO::File;

my $test_name = undef;
my $test_count = 0;

$test_name = "calling without pre-requisites";
$test_count = 1;
eval {
    start_event_tracking();
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    start_event();
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    stop_event();
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    stop_event_tracking();
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    print_event_tracking_results();
    pass("$test_name - $test_count");
    $test_count++;
};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 5; $i++) {
        fail("$test_name - $i");
    }
}

$test_name = "start_event_tracking/stop_event_tracking";
$test_count = 1;
eval {
    start_event_tracking($logger);
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    stop_event_tracking();
    ok((defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 2; $i++) {
        fail("$test_name - $i");
    }
}

$test_name = "start_event_tracking/stop_event_tracking/print_event_tracking_results";
$test_count = 1;
eval {
    start_event_tracking($logger, "foo");
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    stop_event_tracking();
    ok((defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    print_event_tracking_results();
    pass("$test_name - $test_count");
    $test_count++;
};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 3; $i++) {
        fail("$test_name - $i");
    }
}

$test_name = "start_event_tracking/sub-events/stop_event_tracking/print_event_tracking_results";
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
    print_event_tracking_results();
    pass("$test_name - $test_count");
    $test_count++;
};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 9; $i++) {
        fail("$test_name - $i");
    }
}

$test_name = "start_event_tracking/sub-events/stop_event_tracking/print_event_tracking_results (no event tags)";
$test_count = 1;
eval {
    start_event_tracking($logger);
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    start_event();
    pass("$test_name - $test_count");
    $test_count++;
    start_event();
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;
    start_event();
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
    print_event_tracking_results();
    pass("$test_name - $test_count");
    $test_count++;
};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 9; $i++) {
        fail("$test_name - $i");
    }
}

$test_name = "print_event_tracking_results (logger)";
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
    print_event_tracking_results($logger);
    pass("$test_name - $test_count");
    $test_count++;
};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 9; $i++) {
        fail("$test_name - $i");
    }
}

$test_name = "print_event_tracking_results (\$fh)";
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
    print_event_tracking_results(new IO::File ">&STDOUT");
    pass("$test_name - $test_count");
    $test_count++;
};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 9; $i++) {
        fail("$test_name - $i");
    }
}

$test_name = "print_event_tracking_results (filename)";
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
    print_event_tracking_results(new IO::File "&STDOUT");
    pass("$test_name - $test_count");
    $test_count++;
};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 9; $i++) {
        fail("$test_name - $i");
    }
}

$test_name = "start_event_tracking/sub-events/stop_event_tracking/print_event_tracking_results (with notes)";
$test_count = 1;
eval {
    start_event_tracking($logger, "foo");
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    start_event("sub1a", "notation 1");
    pass("$test_name - $test_count");
    $test_count++;
    start_event("sub2a", "notation 2");
    pass("$test_name - $test_count");
    $test_count++;
    stop_event();
    pass("$test_name - $test_count");
    $test_count++;
    start_event("sub2b", "this is a very long note, which you shouldn't do, but it can't be helped that people don't think things through from time to time.");
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
    print_event_tracking_results();
    pass("$test_name - $test_count");
    $test_count++;
};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 9; $i++) {
        fail("$test_name - $i");
    }
}

$test_name = "sequential start_event_tracking/sub-events/stop_event_tracking";
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
    print_event_tracking_results();
    pass("$test_name - $test_count");
    $test_count++;

    start_event_tracking($logger, "foo2");
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
    print_event_tracking_results();
    pass("$test_name - $test_count");
    $test_count++;
};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 18; $i++) {
        fail("$test_name - $i");
    }
}

$test_name = "nested start_event_tracking/sub-events/stop_event_tracking";
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
    
    start_event_tracking($logger, "foo2");
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
    ok((not defined(get_event_tracking_results())), "$test_name - $test_count");
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
    print_event_tracking_results();
    pass("$test_name - $test_count");
    $test_count++;

};
if ($@) {
    diag($@);
    for (my $i = $test_count; $i <= 18; $i++) {
        fail("$test_name - $i");
    }
}

$test_name = "start_event_tracking/EXCEPTION/stop_event_tracking";
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

    die "ARGH!  I'm DEAD!";    
};
if ($@) {
    stop_event_tracking();
    ok((defined(get_event_tracking_results())), "$test_name - $test_count");
    $test_count++;
    print_event_tracking_results();
    pass("$test_name - $test_count");
    $test_count++;
}


exit 0;

# ------------------------------------------------------------------------------
#  $Log$
# ------------------------------------------------------------------------------