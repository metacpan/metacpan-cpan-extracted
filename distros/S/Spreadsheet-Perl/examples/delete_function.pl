
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl" ;
my $ss = tied %ss ;

$ss{'A1:A5'} = 5 ;
$ss{'A1:A5'} = DeleteFunction('called when cell is deleted', \&DeleteCallback, 1, 2, 3) ;

for($ss->GetCellList())
	{
	delete $ss{$_} ;
	print $ss->DumpTable() ;
	}

#------------------------------------------------------------------

sub DeleteCallback
{
my ($ss, $address, $arg1, $arg2) = @_ ;

print "Delete Callback for cell '$address' $arg1 $arg2\n" ;

return(1) ;
}