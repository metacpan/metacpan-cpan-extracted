
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl" ;
my $ss = tied %ss ;
$ss->SetName('TEST') ;

sub OnlyLetters 
{
my ($ss, $current_address, $current_cell, $value, @other_args) = @_ ;

if(defined($value) && ('' eq ref $value) && $value =~ /^[a-zA-Z_]+$/)
	{
	return(1) ;
	}
else
	{
	my $ss_name = $ss->GetName() . '!' ;
	
	my $value_string = "'$value'" if(defined $value) ;
	$value_string    = 'undef' unless(defined $value) ;
	
	print "Not valid: $value_string @ '$ss_name$current_address'.\n" ;
	return(0) ;
	}
}

$ss{'A1:A2'} = Validator('only letters', \&OnlyLetters) ;
print $ss->Dump() ;

$ss{'A1:A2'} = undef ;
$ss{A1} = '' ;
$ss{A1} = 1 ;
$ss{A1} = {} ;
$ss{A1} = 'hi' ;
$ss{A1} = PerlFormula('$ss{A2}') ;

$ss->{DEBUG}{VALIDATOR}++ ; # display calls to all validators in spreadsheet
$ss{A1} = 0 ;
$ss{A1}++ ;

