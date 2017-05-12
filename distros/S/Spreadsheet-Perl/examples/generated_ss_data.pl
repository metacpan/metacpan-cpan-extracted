use Spreadsheet::Perl::Formula ;
SetBuiltin qw(log sin cos) ;



# Couldn't serialize function 'AddOne'.

DefineSpreadsheetFunction('Nadim', undef, <<'DSF') ;
sub
{
my $ss = shift ;
my $address = shift ;
tie my (%ss), $ss ;

#return($ss->Sum('A1:A2')) ;
return("Nadim") ;
}
DSF

use Spreadsheet::Perl::Arithmetic ;
use Spreadsheet::Perl::Arithmetic ;

#-------------------------------------------------------------------------------
# spreadsheet data, a hash reference
#-------------------------------------------------------------------------------
{ 

#-------------------------------------------------------------------------------
# spreadsheet setup
#-------------------------------------------------------------------------------
# default values will be set, we can override them
AUTOCALC => 0,
CACHE => 1,
DEBUG => {
          'FETCH_TRIGGER' => {},
          'STORE_TRIGGER' => {},
          'INLINE_INFORMATION' => 1,
          'ERROR_HANDLE' => \*::STDERR
        },
MESSAGE => {
          'ERROR' => '#error',
          'NEED_UPDATE' => '#need update'
        },
NAME => 'Yasmin',
NAMED_ADDRESSES => {
          'FIRST_CELL' => 'A1'
        },
#-------------------------------------------------------------------------------
# cell data
#-------------------------------------------------------------------------------
CELLS =>
	{
	A1 => 120,
	A2 => PerlFormula(q~$ss->AddOne("A1") + $ss->Sum("A1:B1")~),
	A3 => PerlFormula(q~$ss{FIRST_CELL}~),
	A4 => sub { "DUMMY" },
	A5 => PerlFormula(<<'EOF'),
# example of a multiline formula
# this is perl code!
my $first_cell_value = $ss{FIRST_CELL} ;

my $modified_value = $first_cell_value + 1 ;

return($modified_value) ;
EOF
	A6 => [
          123,
          {
            'Hi' => 'THERE'
          }
        ],
	A7 => PerlFormula(q~$ss->Nadim()~),
	A8 => PerlFormula(q~$ss{A1} + $ss{A2} + $ss->Sum("A1:A2")~),
	A9 => PerlFormula(q~log($ss{A1} + $ss{A2})~),
	B1 => 3,
	C2 => 'hi there',
	D1 => 1000000,
	}
} ;

