
use Carp ;
use strict ;
use warnings ;
use Data::TreeDumper ;

use Spreadsheet::Perl ;
use Spreadsheet::Perl::Arithmetic ;

my $ss = tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;
 
$ss{A0} = 'column 1' ;
$ss{'@1'} = 'row 1' ; 

$ss->{DEBUG}{INLINE_INFORMATION}++ ;

$ss{'A1:C6'} = RangeValuesSub(\&Filler) ;
$ss{'A8:C9'} = PF('$ss{[A]1} + $ss{A3} + $ss->Sum("A1:A4")') ;

$ss{A10} = FetchFunction('fixed address', sub{$ss{A4}}) ;
$ss{A11} = PF('$ss{A4}') ;

print $ss->DumpTable() ;
#~ print $ss->DumpTable(undef, undef, {alignHeadRow => 'center'}) ;
#print $ss->Dump() ;

sub Filler 
{
my ($ss, $anchor, $current_address, $list, @other_args) = @_ ;
my ($column, $row) =  ConvertAdressToNumeric($current_address) ;

return($row) ;
}
