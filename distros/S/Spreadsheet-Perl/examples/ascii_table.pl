
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;
my $ss = tied %ss ;

# fill the cells with their own address
$ss{'A1:H10'} = RangeValuesSub(sub {$_[2]}) ;
$ss{'A1'} = "hi\nthere" ;

$ss->SetNames("NAMED_RANGE", "A4:K5") ;

print $ss->DumpTable(['B4:C5', 'A2:B6', 'NAMED_RANGE']) ;

print $ss->DumpTable(undef, 1) ;

print $ss->DumpTable(undef, undef, { drawRowLine => 0 }) ;

print $ss->DumpTable
		(
		  ['A1:B2']
		, undef
		, undef
		, ['L','R','l','D']  # LllllllDllllllR
                , ['L','R','D']      # L info D info R
                , ['L','R','l','D']  # LllllllDllllllR
                , ['L','R','D']      # L info D info R
                , ['L','R','l','D']   # LllllllDllllllR
		);

# might generate a mess as the page width maybe  smaller than the screen width
print $ss->DumpTable(['A4:AD5'], undef, {pageWidth => 78}) ;
print $ss->DumpTable(['A4:AD5'], undef, {pageWidth => 47}) ;
print $ss->DumpTable(['A4:AD5'], undef, {pageWidth => 120}) ;

# screen width automatically taken into account
# when no page width is given
print $ss->DumpTable
		(
		  ['A4:AD5']
		, undef
		, {
		    #~ alignHeadRow => 'center',
		  #~ , headingText  => $ss->GetName()
		  #~ , noPageCount  => 1
		  }
		) ;

