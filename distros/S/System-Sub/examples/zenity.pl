#!/usr/bin/env perl
use lib '../lib';
use System::Sub 'zenity';

# The sub will die if status is not 0
# But exit status of zenity is 1 for the cancel button
# so we have to catch that
eval {
    zenity '--question',
           '--no-markup',
           '--title' => 'System::Sub test',
	   '--text' => 'How are you today?',
	   '--ok-label' => 'Fine!',
	   '--cancel-label' => 'Tired.';
};

my $status = $? >> 8;
print "$status\n";

if ($status == 0) {
    print "Great!\n"
} elsif ($status == 1) {
    print "Have a nap!\n"
}
