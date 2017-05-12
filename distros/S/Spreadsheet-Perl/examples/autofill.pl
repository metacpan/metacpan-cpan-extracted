
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

#autofill is just a construction of the mind!

tie my %ss, "Spreadsheet::Perl" ;
my $ss = tied %ss ;

my $week_days = [qw(dimanche lundi mardi mercredi jeudi vendredi samedi)] ;

$ss{'A1:F1'} = RangeValuesSub(\&WeekDayFiller, $week_days, 'mardi') ;
$ss{'A1:A8'} = RangeValuesSub(\&WeekDayFiller, $week_days, 'mardi') ;
print $ss->Dump() ;
print $ss->GenerateASCIITable() ;


#-------------------------------------------------------------

sub WeekDayFiller
{
my ($ss, $anchor, $current_address, $week_days, $start_day) = @_ ;

my $day_offset = 0 ;

for (@$week_days)
	{
	last if $_ eq $start_day ;
	$day_offset++ ;
	}
	
my ($cell_offset_x, $cell_offset_y) = $ss->GetCellsOffset($anchor, $current_address) ;

my $day = ($cell_offset_x + $cell_offset_y + $day_offset) % @$week_days ;

return($week_days->[$day]) ;
}

