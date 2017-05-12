
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl" ;
my $ss = tied %ss ;

my $values ;
my $separator = '-' x 40 . "\n" ;

#--------------------------------------------------------------
PrintSeparator('T1') ;
for('A1', 'A2')
	{
	$ss->{DEBUG}{FETCH_TRIGGER}{$_}++ ;
	}

$ss->{DEBUG}{STORE_TRIGGER}{'A1'}++ ;
$ss{A1} = 1 ;
$values = $ss{A1} ;
$ss{A2} = 1 ;
$values = $ss{A2} ;

#--------------------------------------------------------------
PrintSeparator('T2') ;
$ss->{DEBUG}{FETCH_TRIGGER_HANDLER} = sub {my ($ss, $address) = @_ ; print "TH fetching:'$address'\n"} ;
$ss->{DEBUG}{STORE_TRIGGER_HANDLER} = sub {my ($ss, $address, $value) = @_ ; print "TH storing:'$address'\n"} ;
$ss{A1} = 1 ;
$values = $ss{A1} ;
$values = $ss{A2} ;

#--------------------------------------------------------------
PrintSeparator('T3') ;
$ss->{DEBUG}{STORE_TRIGGER}{'A1'}-- ;
$ss->{DEBUG}{FETCH_TRIGGER}{'A1'} = 0 ;
$ss{A1} = 1 ;
$values = $ss{A1} ;
$values = $ss{A2} ;

#--------------------------------------------------------------
PrintSeparator('T4') ;
$ss->{DEBUG}{STORE_TRIGGER}{'A1'} = sub {my ($ss, $address, $value) = @_ ; print "'A1' storing.\n"} ; ;
$ss{A1} = 1 ;
$values = $ss{A1} ;
$ss{A2} = 1 ;
$values = $ss{A2} ;

#--------------------------------------------------------------
PrintSeparator('T5') ;
$ss->{DEBUG}{FETCH_TRIGGER}{'A2'} = sub {my ($ss, $address) = @_ ; print "'A2' fetching.\n"} ; ;
$ss{A1} = 1 ;
$values = $ss{A1} ;
$ss{A2} = 1 ;
$values = $ss{A2} ;

#--------------------------------------------------------------
#~ PrintSeparator('T') ;

sub PrintSeparator
{
print "\n---------------- $_[0] ----------------\n" ;
}