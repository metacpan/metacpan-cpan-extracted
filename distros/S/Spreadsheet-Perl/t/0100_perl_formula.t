
use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Spreadsheet::Perl ;
use Spreadsheet::Perl::Arithmetic ;

{
local $Plan = {'formulas with Arithmetic module' => 5} ;

my $ss = tie my %ss, "Spreadsheet::Perl" ;
$ss->{DEBUG}{INLINE_INFORMATION}++ ;

$ss{'A1:A4'} = RangeValues(1 .. 8) ;
$ss{A5} = PerlFormula('$ss->Sum("A1:A4") + 100 ') ;

is($ss{A5}, 110, "first formula") or diag $ss->DumpTable() ; 

$ss{A5} = PerlFormula('$ss{A1} + $ss{A2}') ;
is($ss{A5}, 3, "override formula") or diag $ss->DumpTable() ; 

$ss{A1} = 10 ;
is($ss{A5}, 12, "one level dependency detected") or diag $ss->DumpTable() ; 

$ss{A1} = PerlFormula('$ss{A2} + $ss{A3}') ;
is($ss{A5}, 7, "two level dependency formula") or diag $ss->DumpTable() ; 

$ss{A2} = 10 ;
is($ss{A5}, 23, "two level dependency detected") or diag $ss->DumpTable() ; 
}

{
local $Plan = {'formula with perl error' => 2} ;

my $ss = tie my %ss, "Spreadsheet::Perl" ;
$ss->{DEBUG}{INLINE_INFORMATION}++ ;

$ss{'A1:A8'} = RangeValues(1 .. 8) ;
$ss{A9} = PerlFormula(' oops! no perl') ;

lives_ok
	{
	is($ss{A9}, '#error', 'perl formula error') or diag $ss->DumpTable() ; 
	} 'SS:P Caught eval exception' ;
}

{
local $Plan = {'load formula' => 1} ;

my $ss = tie my %ss, "Spreadsheet::Perl" =>
		CELLS =>
			{
			A5 => { PERL_FORMULA => [undef, '$ss->Sum("A1:A4")']} ,
			} ;

$ss->{DEBUG}{INLINE_INFORMATION}++ ;

$ss{'A1:A4'} = RangeValues(1 .. 8) ;
is($ss{A5}, 10, 'load formula') or diag $ss->DumpTable() ; 
}

{
local $Plan = {'PF multiple formulas' => 2} ;

my $ss = tie my %ss, "Spreadsheet::Perl";
$ss->{DEBUG}{INLINE_INFORMATION}++ ;

$ss{'A1:A4'} = RangeValues(1 .. 8) ;

$ss->PF
	(
	B1 => '$ss{A1} * 2',
	B2 => '$ss{A2} * $ss{A2}'
	) ;
	
is($ss{B1}, 2, 'B1 formula') or diag $ss->DumpTable() ; 
is($ss{B2}, 4, 'B2 formula') or diag $ss->DumpTable() ; 
}

{
local $Plan = {'formulas shifting' => 2} ;

my $ss = tie my %ss, "Spreadsheet::Perl";
$ss->{DEBUG}{INLINE_INFORMATION}++ ;

$ss{'A1:A4'} = RangeValues(1 .. 8) ;

$ss->PF('B1:B4' => '$ss{A1} * 2') ;
	
is($ss{B1}, 2, 'B1 formula') or diag $ss->DumpTable() ; 
is($ss{B4}, 8, 'B4 formula') or diag $ss->DumpTable() ; 
}

=comment

{
local $Plan = {'' => } ;

is(result, expected, 'message') ;

throws_ok
	{
	
	} qr//, '' ;

lives_ok
	{
	
	} '' ;

like(result, qr//, '') ;

warning_like
	{
	} qr//i, '';

warnings_like
	{
	}
	[
	qr//i,
	qr//i,
	] '';


is_deeply
	(
	generated,
	[],
	''
	) ;

=cut
