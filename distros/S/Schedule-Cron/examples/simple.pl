#!/usr/bin/perl

# Very simple examples which print the current 
# time every 10 Minutes.
#
# The purpose is to show a common usage pattern 
# using a single dispatcher subroutine provided
# at construction time

use lib "../lib";
use Schedule::Cron;

# Create new object with default dispatcher
my $cron = new Schedule::Cron(\&dispatcher);

# The cron entry which fires every 10 minutes
my $entry = "0-59/5 * * * *";

# Dispatcher subroutine called from cron
sub dispatcher { 
    open(T,">>timestamps.txt");
    print T "Current: ",scalar(localtime),"\n";
    print T "Next:    ",scalar(localtime($cron->get_next_execution_time($entry))),"\n";
    close T;
    sleep(30);
}


# Call &dispatcher() every ten minutes
$cron->add_entry($entry);

# Run scheduler and block. 'nofork' forces the subroutine to 
# be called in the main process
$cron->run(nofork=>1);
