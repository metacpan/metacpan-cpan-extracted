
use Carp ;
use strict ;
use warnings ;
use Data::TreeDumper ;

use Spreadsheet::Perl ;
use Spreadsheet::Perl::Arithmetic ;

my $ss = tie my %ss, "Spreadsheet::Perl" ;

$ss{A7} = 5 ;
$ss{A8} = 3 ;
$ss{A9} = PerlFormula
		(
		'
		my $dh = $ss->{DEBUG}{ERROR_HANDLE} ;
		print $dh "Doing something\n" ;
		$ss->Sum("A1:A7", "A8") ;
		'
		) ;

print "$ss{A9}\n" ;

