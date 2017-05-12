
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;
use Spreadsheet::Perl::Arithmetic ;

my $ss = tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;

$ss{A9} = PerlFormula('$ss->Sum("A1:A8") + 100 ') ;

$ss{'A1:A8'} = RangeValues(1 .. 8) ;
print $ss->Dump() ; # show formula dependencies

print "$ss{A9}\n" ;

$ss{A9} = PerlFormula('$ss{A1} + $ss{A2}') ;
print "$ss{A9}\n" ;

$ss{A10} = PerlFormula('"$cell => " . (join "-", (ConvertAdressToNumeric($cell)))') ;
print "'A10' Self: " . $ss{A10} . "\n" ;


$ss->PF
	(
	  B1 => 'cos($ss{A1} + $ss{A2})'
	, B2 => '$ss{A4} + $ss{A3}'
	, 'B3:B5' => '$ss{A4} + $ss{A3}'
	) ;
	
$ss->{DEBUG}{INLINE_INFORMATION}++ ;
print $ss->DumpTable() ;

