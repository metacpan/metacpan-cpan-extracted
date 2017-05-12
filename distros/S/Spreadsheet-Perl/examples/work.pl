
use Spreadsheet::Perl ;

use Carp ;
use strict ;
use warnings ;

use Data::TreeDumper ;
use Spreadsheet::ConvertAA ;

#-------------------------------------------------------------------------------

my $ss = tie my %ss, "Spreadsheet::Perl", NAME => 'NAME' ;
$ss->{DEBUG}{FETCH}++ ;
$ss->{DEBUG}{FETCH_VALUE}++ ;

$ss->SetNames( C => 'NAME!B1') ;
@ss{'C'} = 1 ;

print "@ss{'C'}\n" ;

