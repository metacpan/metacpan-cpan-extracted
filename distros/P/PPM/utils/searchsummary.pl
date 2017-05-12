#!perl
#
# Prints to STDOUT a summary file of all PPD files in the 
# current directory.
#
# This produces the same output as 'summary.pl', with the addition 
# of bare (ARCHITECTURE only) IMPLEMENTATION sections, which makes
# for somewhat more efficient server-side searches than a full-blown
# REPOSITORYSUMMARY.
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
    $data =~ s@\s+<\bOS\b.*?/>@@gs;
    $data =~ s@\s+<\bCODEBASE\b.*?/>@@gs;
    $data =~ s@\s+<\bDEPENDENCY\b.*?/>@@gs;
    print $data;
}
print "</REPOSITORYSUMMARY>\n";
