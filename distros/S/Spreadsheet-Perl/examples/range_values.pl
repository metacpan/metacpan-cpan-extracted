
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl" ;
my $ss = tied %ss ;

$ss{'A1:A5'} = RangeValues(reverse 1 .. 10) ;
print $ss->Dump(['A1:A5']) ;

$ss{'A1:A5'} = RangeValuesSub(\&Filler, [11, 22, 33]) ;
print $ss->Dump(['A1:A5'], 0) ;

@ss{'A1', 'B1:C2', 'A8'} = ('A', RangeValues(reverse 1 .. 10), -1) ;
print $ss->Dump() ;

@ss{'A1', 'B1:C2', 'A8'} = ('A', 'B', 'C');
print $ss->Dump() ;

@ss{'A1:A5'} = 'data' x 10 ;
print $ss->Dump(undef, 0, {DISPLAY_PERL_SIZE => 1}) ;
print $ss->DumpTable
		(
		  undef
		, undef 
		, {
		    alignHeadRow => 'center',
		  , headingText  => 'Some Title'
		  }
		) ;

#~ print $ss->Dump(undef, 0, {DISPLAY_PERL_SIZE => 1, DISPLAY_PERL_ADDRESS => 10}) ;
#~ use Devel::Size::Report qw/report_size/;
#~ print report_size($ss->{CELLS}, { indend => "    " } );


#-------------------------------------------------------------

sub Filler 
{
my ($ss, $anchor, $current_address, $list, @other_args) = @_ ;
return(shift @$list) ;
}

