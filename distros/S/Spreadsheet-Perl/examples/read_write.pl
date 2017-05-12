
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

my $ss = tie my %ss, "Spreadsheet::Perl" ;

$ss->Read('ss_data.pl') ;

$ss->{DEBUG}{INLINE_INFORMATION}++ ;
#$ss->{DEBUG}{PRINT_FORMULA}++ ;

$ss{A3} = PF('$ss{FIRST_CELL}') ;

Spreadsheet::Perl::SetBuiltin qw( log sin cos ) ;

if(0) # set to use common formula format
	{
	$ss{A8} = Formula('A1 + A2 + Sum(A1:A2)') ;
	$ss{A9} = Formula('log(A1 + A2)') ;
	}
else
	{
	$ss{A8} = PF('$ss{A1} + $ss{A2} + $ss->Sum("A1:A2")') ;
	$ss{A9} = PF('log($ss{A1} + $ss{A2})') ;
	}
	
print $ss->DumpTable() ;
#print $ss->Dump(undef, undef, {USE_ASCII => 1}) ;

$ss->Write('generated_ss_data.pl') ;

Spreadsheet::Perl::SetBuiltin qw() ;
%Spreadsheet::Perl::defined_functions = () ;

undef $ss ;
%ss = () ;
untie %ss ;

$ss = tie %ss, "Spreadsheet::Perl" ;
$ss->Read('generated_ss_data.pl') ;

print $ss->DumpTable() ;
#print $ss->Dump(undef, undef, {USE_ASCII => 1}) ;

#~ for (sort keys %Spreadsheet::Perl::defined_functions)
	#~ {
	#~ print "Found function '$_' in the spreadsheet.\n" ;
	#~ }
	
