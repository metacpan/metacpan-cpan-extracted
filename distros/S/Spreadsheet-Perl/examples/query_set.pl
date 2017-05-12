
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;
my $ss = tied %ss ;

$ss{'A1:A4'} = PerlFormula('$ss{A5}') ;
$ss{C3}++ ;

print "Cells: " . (join " - ", $ss->GetCellList()) . "\n" ;
print "Last Indexes: " . (join " - ", $ss->GetLastIndexes()) . "\n" ;

$ss{A5}++ ;
print $ss->GetCellsToUpdateDump() ;

print $ss->Dump() ;

# generate errors 
#~ $ss->Reset(NAME => 'NEW_TEST') ;
#~ $ss->Reset({NAME => 'NEW_TEST'}, A1 => {VALUE => 0}) ;

$ss->Reset({NAME => 'NEW_TEST'}, {A1 => {VALUE => 7}}) ;

print $ss->Dump(undef, 1) ;
