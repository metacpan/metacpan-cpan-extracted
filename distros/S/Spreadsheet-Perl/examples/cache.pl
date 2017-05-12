
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;
use Spreadsheet::Perl::Arithmetic ;

use Data::Dumper ;

tie my %ss, "Spreadsheet::Perl" ;
my $ss = tied %ss ;

# cached value is returned even if the ss is changed
$ss{A1} = FetchFunction('', sub{ use Data::Dumper; return($ss->Dump()) ;}) ;
$ss{A2} = 'hi' ;
print "$ss{A1}\n" ;

$ss{A2} = 'there' ;
print $ss{A1} . "\n" ; #!!  cached value is returned

$ss{A1} = NoCache() ;
$ss{A1} = FetchFunction('', sub{ use Data::Dumper; return($ss->Dump(undef, 1)) ;}) ;
$ss{A2} = 'hi' ;
print $ss{A1} . "\n" ;

$ss{A2} = 'there' ;
print $ss{A1} . "\n" ; # Ok

print "No cache at the spreadsheet level\n";
%ss = () ;
$ss->NoCache() ;

$ss{A1} = FetchFunction('', sub{ use Data::Dumper; return($ss->Dump(['A1'], undef, {USE_ASCII => 1})) ;}) ;
$ss{A2} = 'hi' ;
print "$ss{A1}\n" ;

$ss{A2} = 'there' ;
print $ss{A1} . "\n" ; 

#~ print $ss->DumpTable() ;