
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;
use Spreadsheet::Perl::Arithmetic ;

SetBuiltin qw( log sin cos ) ;

my $ss = tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;

$ss{A9} = Formula('Sum(A1:A8) + 100 ') ;
$ss{'A1:A8'} = RangeValues(1 .. 8) ;

$ss->Formula
	(
	  B1 => 'cos(A1 + A2)'
	, B2 => 'A4 + A3'
	, 'B3:B5' => 'log(A4) + A3'
	, 'B6:b7' => 'Sum(A4:A5) + Sum(A3)'
	, B8 => 'log(A4:A5) + log(A3)'
	) ;

$ss->{DEBUG}{INLINE_INFORMATION}++ ;
print $ss->DumpTable() ;
$ss->Recalculate() for (1 .. 1) ;

#~ print $ss->Dump() ; # show formula dependencies
