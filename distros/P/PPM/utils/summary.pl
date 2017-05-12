#!perl
#
# Prints to STDOUT a summary file of all PPD files in the 
# current directory.
#
# This is essentially *.ppd wrapped in <REPOSITORYSUMMARY>,
# but without the IMPLEMENTATION sections.  Compared to the
# original summary format (with IMPLEMENTATION sections), 
# this results in a file approximately 25% the size.
#
# Author: Murray Nesbitt (murray@cpan.org)
#

use strict;

print "<REPOSITORYSUMMARY>\n";
foreach(<*.ppd>) {
    local $/;
    open(PPD, "<$_") or die "Can't open $_ for reading: $!";
    my $data = <PPD>;
    close PPD;
    $data =~ s@<IMPLEMENTATION>.*?</IMPLEMENTATION>@@gs;
    print $data;
}
print "</REPOSITORYSUMMARY>\n";
