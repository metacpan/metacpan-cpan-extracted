#!/usr/bin/perl
###############################################################################

use strict;
use warnings;

print "Hello world.\n" if ( @ARGV );

my $code_ref = sub { print "Hi there\n"; }; # Will not be counted
exit;

sub foo {};
sub bar {
    # This is the second line of the sub
    
    # This is the fourth line of the sub
}
