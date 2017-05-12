#!/usr/bin/perl
# $Header: /Library/VersionControl/CVS/Perl-Metrics-Simple/t/test_files/subs_no_package.pl,v 1.4 2006/09/24 19:18:06 matisse Exp $
# $Revision: 1.4 $
# $Author: matisse $
# $Source: /Library/VersionControl/CVS/Perl-Metrics-Simple/t/test_files/subs_no_package.pl,v $
# $Date: 2006/09/24 19:18:06 $
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