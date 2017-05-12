
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl" ;
my $ss = tied %ss ;

$ss{'A1:A8'} = 10 ;

$ss{A9} = FetchFunction('sum rows above this one', \&SumRowsAbove) ;
print "'A9' SumRowsAbove: " . $ss{A9} . "\n" ;

#-------------------------------------------------------------------------------

sub SumRowsAbove
{
my $ss = shift ;
my $address  = shift ;

my ($x, $y) = ConvertAdressToNumeric($address) ;

my $sum = 0 ;

for my $current_y (1 .. ($y - 1))
	{
	my $cell_value = $ss->Get("$x,$current_y") ;
	
	$sum += $cell_value ; # should check if value is numeric
	}
	
return($sum) ;
}

# dependency OK
%ss = () ;
$ss{A1} = FetchFunction('test', sub{return($_[0]->Get('A2') ) ;}) ; # sub is passed $self && $cell_address
$ss{A2} = 'hi' ;
print $ss{A1} . "\n" ;
$ss{A2} = 'there' ;
print $ss{A1} . "\n" ;

print $ss->DumpTable() ;

$ss->{DEBUG}{INLINE_INFORMATION}++ ;
print $ss->DumpTable() ;

