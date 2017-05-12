
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;
use Spreadsheet::Perl::Arithmetic ;

#---------------------------------------------------------------------------------

tie my %ss, "Spreadsheet::Perl"
		, CELLS =>
				{
				  A1 =>
						{
						VALUE => 'hi'
						}
					
				, A2 =>
						{
						VALUE => 'there'
						}
				} ;

my $ss = tied %ss ;

#~ print  $ss{A1} . ' ' . $ss{A2} . "\n" ;
print "1\n" . $ss->Dump() ;

#---------------------------------------------------------------------------------

tie %ss, "Spreadsheet::Perl"
		, CELLS =>
				{
				  A1 =>
						{
						VALUE => 1
						}
					
				, A2 =>
						{
						  FETCH_SUB => \&DoublePrevious
						, FETCH_SUB_ARGS => [ 1, 2, 3]
						
						#~ PERL_FORMULA => ['$ss{A1}']
						}
				} ;

$ss = tied %ss ;
print "2\n" . $ss->Dump() ;

#~ print  $ss{A1} . ' ' . $ss{A2} . "\n" ;

print "3\n" . $ss->DumpTable() ;
print "3bis\n" . $ss->Dump() ;

sub DoublePrevious
{
my $ss = shift ;
my $address  = shift ;

my ($x, $y) = ConvertAdressToNumeric($address) ;
my $cell_value = $ss->Get("$x," . ($y - 1)) ;

return($cell_value * 2) ;
}

#---------------------------------------------------------------------------------

tie %ss, "Spreadsheet::Perl"
		, CELLS =>
				{
				  A1 =>
						{
						VALUE => 'hi'
						}
					
				, A2 =>
						{
						  VALUE => 'there'
						, PERL_FORMULA => [undef, '$ss{A1}']
						#~ , FORMULA => [undef, 'A1']
						}
				} ;

$ss = tied %ss ;

print "4\n" . $ss->Dump() ;
print  $ss{A1} . ' ' . $ss{A2} . "\n" ;

#---------------------------------------------------------------------------------
# error that we can't cach as of 0.04, we don't differentiate between formula 
# generated FETCH_SUB anf sub comming from setup
#---------------------------------------------------------------------------------

tie %ss, "Spreadsheet::Perl"
		, CELLS =>
				{
				  A1 =>
						{
						VALUE => 'hi'
						}
					
				, A2 =>
						{
						VALUE => 'there'
						
						, FETCH_SUB => \&DoublePrevious
						, FETCH_SUB_ARGS => [ 1, 2, 3]
						, FORMULA => [undef, 'A1'] # ignored when fetch sub already defined
						}
				} ;

$ss = tied %ss ;

print "5\n" . $ss->Dump() ;
print  $ss{A1} . ' ' . $ss{A2} . "\n" ;

#---------------------------------------------------------------------------------

%ss = do "ss_setup.pl" or confess("Couldn't evaluate setup file 'ss_setup.pl'\n");

print "6\n" . $ss->Dump() ;
$ss->GenerateHtmlToFile('setup_do.html') ;
print $ss->DumpTable() ;

#---------------------------------------------------------------------------------
