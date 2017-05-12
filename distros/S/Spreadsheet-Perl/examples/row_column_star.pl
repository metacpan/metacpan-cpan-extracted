
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl" ;
my $ss = tied %ss ;
$ss->{DEBUG}{ADDRESS_LIST}++ ;

$ss{'A*:B*'} = 0 ;
$ss{'*1:C*'} = 0 ;
$ss{'*:C*'} = 0 ;
$ss{'*'} = 10 ;
$ss{'B*'} = 10 ;
$ss{'*1'} = 10 ;

print $ss->Dump(['A1']) ;
