
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl" ;
my $ss = tied %ss ;
@ss{'A1', 'A2'} = ('cell A1', 'cell A2') ;

$ss->SetNames("NAME", "1,1") ;
print "T1:" . $ss{NAME} . ' ' . $ss{A2} . "\n" ;

$ss->SetNames("NAME", "A1") ;
print "T2:" . $ss{NAME} . ' ' . $ss{A2} . "\n" ;

$ss->SetNames("NAME", "A1:A2") ;
print "T3:" . "First range: @{$ss{NAME}}\n" ;

$ss->Lock(1) ;
$ss{A1} = 'ho' ;
$ss->Lock(0) ;

$ss{"1,1"} = "cell A1(m)" ; # numeric indexing is also possible

print "T4:" . $ss{NAME} . ' ' . $ss{A2} . "\n" ;

$ss->LockRange("A1:B1", 1) ;
$ss{A1} = 'ho' ;
$ss{C1} = 'ho' ; # not locked

$ss->SetNames("NAME", 'A1:B5') ;
$ss{NAME} = '7' ;

$ss->{DEBUG}{INLINE_INFORMATION}++ ;
print $ss->DumpTable() ;

$ss->SetNames('A1:B5', 'A1:B5') ;

