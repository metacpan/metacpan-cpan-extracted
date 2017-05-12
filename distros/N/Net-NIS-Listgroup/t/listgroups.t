#!/usr/local/bin/perl

#
#  $Id: listgroups.t,v 1.2 2003-01-21 12:25:32-05 mprewitt Exp $
#

BEGIN {
    unshift @INC, "..";
}

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::NIS::Listgroup;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $groups;
eval { $groups = Net::NIS::Listgroup::listgroups(); };
if ($@) {
    print "not ok 2 [$@]\n";
} else {
    print "netgroup keys: ", join (" ", @$groups), "\n";
    print "ok 2\n";
}

my $error;
foreach my $group (@$groups) {
    print "group: $group = ";
    my $members;
    eval { $members = Net::NIS::Listgroup::listgroup($group); };
    if ($@) {
        $error = 1;
    } else {
        print join (" ", @$members), "\n";
    }
}
if ($error) {
    print "not ok 3 [$@]\n";
} else {
    print "ok 3\n";
}
