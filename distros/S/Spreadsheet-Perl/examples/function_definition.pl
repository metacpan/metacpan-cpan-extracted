
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

my $ss = tie my %ss, "Spreadsheet::Perl" ;

@ss{'A1', 'A2'} = (1 .. 2) ;

DefineSpreadsheetFunction('AddOne', \&AddOne) ;
DefineSpreadsheetFunction('AddOne', \&AddOne) ; # generate a warning

$ss{A3} = PerlFormula('$ss->AddOne("A1") + $ss{A2}') ;
print $ss->Dump() ;

print "A3 => '@{[$ss->GetFormulaText('A3')]}' = $ss{A3}\n" ;

#---------------------------------------------------

sub AddOne
{
my $ss = shift ;
my $address = shift ;

return($ss->Get($address) + 1) ;
}
