
package ss_data ;
use Spreadsheet::Perl ;
use Spreadsheet::Perl::Arithmetic ;

# helper function to compute start data for a cell
sub OneMillion
{
return(1_000_000) ;
}

# Function we want to be available within the spreadsheet
sub AddOne
{
my $ss = shift ;
my $address = shift ;
tie my (%ss), $ss ;

return($ss->Get($address) + 1) ;
}

DefineSpreadsheetFunction('AddOne', \&AddOne) ;

DefineSpreadsheetFunction('Nadim', undef, <<'EOF') ;
sub
{
my $ss = shift ;
my $address = shift ;
tie my (%ss), $ss ;

#return($ss->Sum('A1:A2')) ;
return("Nadim") ;
}
EOF

#-----------------------------------------------------------------
# spreadsheet data, a hash reference
#-----------------------------------------------------------------
{ 

#-----------------------------------------------------------------
# spreadsheet setup
#-----------------------------------------------------------------
# default values will be set, we can override them
AUTOCALC => 0 ,
CACHE => 1 ,
DEBUG =>
	{
	#INLINE_INFORMATION => 1
	} ,
	
ERROR_HANDLER => undef, 

MESSAGE =>
	{
	ERROR => '#error',
	NEED_UPDATE => '#need update'
	},
	
NAME => 'Yasmin',

NAMED_ADDRESSES =>
	{
	FIRST_CELL => 'A1'
	} ,
      
#-----------------------------------------------------------------
# cell data
#-----------------------------------------------------------------
CELLS =>
	{
	A1 => 120, 
	A2 => PerlFormula('$ss->AddOne("A1") + $ss->Sum("A1:B1")'),
	A4 => sub{1},
	A5 => PerlFormula(<<'EOF') ,
# example of a multiline formula
# this is perl code!
my $first_cell_value = $ss{FIRST_CELL} ;

my $modified_value = $first_cell_value + 1 ;

return($modified_value) ;
EOF
	A6 => [123, {Hi => 'THERE'}] ,
	A7 => PF('$ss->Nadim()') ,
	
	B1 => 3,
	
	C2 => "hi there",
	
	D1 => OneMillion()
	}
} ;


