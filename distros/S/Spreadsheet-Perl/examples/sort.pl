
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl" ;
my $ss = tied %ss ;

print "$_\n" for (Spreadsheet::Perl::SortCells($ss->GetAddressList("A1:A10", "THAT!B3:D4")))
