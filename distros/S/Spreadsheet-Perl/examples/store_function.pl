
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl" ;
my $ss = tied %ss ;

$ss{'A1:A5'} = StoreFunction('', \&StorePlus, 5) ;
$ss{'A6:A10'} = StoreFunction('', \&StorePlus, 10) ;
$ss{'A1:A10'} =  5 ;

for($ss->GetCellList(), 'A11')
	{
	print "\$ss{$_} = $ss{$_}\n" ;
	}

#------------------------------------------------------------------

sub StorePlus
{
my ($ss, $address, $value_to_store, $increment) = @_ ;

$ss->{CELLS}{$address}{VALUE} = $value_to_store + $increment ;
}