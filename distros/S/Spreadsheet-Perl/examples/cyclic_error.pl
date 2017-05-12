
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl", NAME=> 'TEST' ;
my $ss = tied %ss ;

$ss->{DEBUG}{DEPENDENT}++ ;
$ss->{DEBUG}{FETCH}++ ;
$ss->{DEBUG}{STORE}++ ;
$ss->{DEBUG}{SUB}++ ;

#~ # cyclic error
$ss->{DEBUG}{DEFINED_AT}++ ;
$ss{'A1:A5'} = PerlFormula('$ss{"A2"}') ;
$ss{A6} = PF('$ss{A1}') ;

print $ss->DumpTable() ;
print "$ss{A1}\n" ;

