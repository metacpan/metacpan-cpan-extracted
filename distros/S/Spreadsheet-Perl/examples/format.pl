
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl" ;
my $ss = tied %ss ;

$ss{A1} = Format(ANSI => {HEADER => "blink"}) ;
print $ss->Dump() ;

$ss{A1} = Format(ANSI => {HEADER => "red_on_black"}) ;
print $ss->Dump() ;

$ss{A1} = Format(POD => {FOOTER => "B<>"}) ;
print $ss->Dump() ;

$ss{A1} = Format('ERROR') ; # only name is apssed not format
