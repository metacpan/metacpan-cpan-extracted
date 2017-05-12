
use Carp ;
use strict ;
use warnings ;
use Data::TreeDumper ;

use Spreadsheet::Perl ;
use Spreadsheet::Perl::Arithmetic ;

tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;
my $ss = tied %ss ;

$ss{A3} = PF('$ss{A1} + $ss{A2}') ;
$ss{A3} = StoreOnFetch() ;
$ss{A3} = StoreFunction('formula to db', \&Store) ;

$ss{'A1:A2'} = 10 ;

print $ss->Dump() ;

$ss->Recalculate() ;

print $ss->Dump() ;

$ss{'A1:A2'} = 10 ;

print $ss->Dump() ;

sub Store
{
my ($ss, $address, $value_to_store) = @_ ;

print "Storing value: $value_to_store\n" ;
$ss->{CELLS}{$address}{VALUE} = $value_to_store ;
}

