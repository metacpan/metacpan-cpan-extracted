
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ; 

my $ss = tie my %ss, "Spreadsheet::Perl" ;

$ss{'A0'} = 'column A' ;
$ss{'@1'} = 'row 1' ;

$ss->label_column('B' => 'column B') ;
$ss->label_row(2 => 'row 2') ;

print $ss->DumpTable() ;

