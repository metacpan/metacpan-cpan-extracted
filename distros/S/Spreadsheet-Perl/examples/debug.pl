
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;
use Spreadsheet::Perl::QuerySet ;
use Spreadsheet::Perl::Devel ;
use Spreadsheet::Perl::Arithmetic ;

tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;
my $ss = tied %ss ;

%ss = do "ss_setup.pl" or confess("Couldn't evaluate setup file 'ss_setup.pl'\n") ;

print $ss->Dump(undef, 0, {USE_ASCII => 1}) ;

$ss->{DEBUG}{SUB}++ ; # show whenever a value has to be calculated
$ss->{DEBUG}{FETCHED}++ ; # counts how many times the cell is fetched
$ss->{DEBUG}{STORED}++ ; # counts how many times the cell is stored

$ss->{DEBUG}{PRINT_FORMULA}++ ; # show the generated formulas
$ss->{DEBUG}{INLINE_INFORMATION}++ ; #inline information about the cell in the 2D dump

$ss->{DEBUG}{DEFINED_AT}++ ; # show where the cell has been defined
$ss->{DEBUG}{ADDRESS_LIST}++ ; # shows the generated address lists
$ss->{DEBUG}{FETCH_FROM_OTHER}++ ; # show when an inter spreadsheet value is fetched
$ss->{DEBUG}{DEPENDENT_STACK}++ ; # show the dependent stack every time a value is fetched
$ss->{DEBUG}{DEPENDENT}++ ; # store information about dependent and show them in dump
$ss->{DEBUG}{VALIDATOR}++ ; # display calls to all validators in spreadsheet


$ss->{DEBUG}{FETCH}++ ; # shows when a cell value is fetched
$ss->{DEBUG}{STORE}++ ; # shows when a cell value is stored
$ss->{DEBUG}{FETCH_TRIGGER}{'A1'}++ ; # displays a message when 'A1' is fetched
$ss->{DEBUG}{FETCH_TRIGGER}{'A1'} = sub {my ($ss, $address) = @_} ; # calls the sub when 'A1' is fetched
$ss->{DEBUG}{FETCH_TRIGGER_HANDLER} = sub {my ($ss, $address) = @_} ; # calls sub when any trigger is fetched and no specific sub exists
$ss->{DEBUG}{STORE_TRIGGER}{'A1'}++ ; # displays a message when 'A1' is stored
$ss->{DEBUG}{STORE_TRIGGER}{'A1'} = sub {my ($ss, $address) = @_} ; # calls the sub when 'A1' is stored
$ss->{DEBUG}{STORE_TRIGGER_HANDLER} = sub {my ($ss, $address, $value) = @_} ; # calls sub when any trigger is stored and no specific sub exists

