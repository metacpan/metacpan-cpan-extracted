
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;
use Data::TreeDumper ;

my $ss = tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;
my $scalar = 5;

$ss{A9} = PerlFormula('print DumpTree \@formula_arguments, "formula args:"', \$scalar,10,15) ;

print "$ss{A9}\n" ;

