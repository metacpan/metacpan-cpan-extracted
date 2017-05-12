
use Spreadsheet::Perl ;

use Carp ;
use strict ;
use warnings ;

use Data::TreeDumper ;
use Spreadsheet::ConvertAA ;

#-------------------------------------------------------------------------------

my $ss = tie my %ss, "Spreadsheet::Perl", NAME => 'NAME' ;

$ss->SetNames
	(
	  NADIM => 'B1'
	, A => 'A1'
	, B => 'A1:A2'
	, C => 'NAME!B1'
	, D => 'NAME!NADIM:B2'
	) ;
		
@ss{'A', 'B', 'C', 'D'} = (1 .. 10) ;

$ss->{DEBUG}{FETCH}++ ;
$ss->{DEBUG}{FETCH_VALUE}++ ;

print "@ss{'A', 'B', 'C', 'D'}\n" ;
print DumpTree([@ss{'A', 'B', 'C', 'D'}], "Slice:") ;

print $ss->DumpTable() ;

print "NAME!B1 offset(1, 2) = " . $ss->OffsetAddress('C' ,1 ,2) ."\n" ;
print "NAME!B1:B2 offset(1, 2) = " . $ss->OffsetAddress('D' ,1 ,2) ."\n" ;
print "NAME!B1:B2 offset(1, 2) = " . $ss->OffsetAddress('NAME!B1:B2' ,1 ,2) ."\n" ;
print "NAME![B]1:B[2] offset(1, 2) = " . $ss->OffsetAddress('NAME![B]1:B[2]' ,1 ,2) ."\n" ;

my $a_address = $ss->CanonizeAddress('A') ;
my $b_address = $ss->CanonizeAddress('B') ;

print "offset between $a_address and $b_address: " . join(', ', $ss->GetCellsOffset('A', 'B')) . "\n" ;
