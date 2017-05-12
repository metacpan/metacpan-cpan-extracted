#!/usr/bin/perl
# $Header: /Library/VersionControl/CVS/Perl-Metrics-Simple/t/test_files/package_no_subs.pl,v 1.4 2006/11/23 22:25:48 matisse Exp $
# $Revision: 1.4 $
# $Author: matisse $
# $Source: /Library/VersionControl/CVS/Perl-Metrics-Simple/t/test_files/package_no_subs.pl,v $
# $Date: 2006/11/23 22:25:48 $
###############################################################################

package Hello::Dolly;

use strict;
use warnings;

START:
print "Hello world.\n";
print "I have a package.\n";
print "I have no subs.\n";

for ( 1..5 ) {
    print "$_\n";
}
goto START;

exit;