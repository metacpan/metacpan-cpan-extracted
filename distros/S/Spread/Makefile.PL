require 5.004 ;
use ExtUtils::MakeMaker 5.16 ;
use Config ;

$SPLIB_LIB = $ENV{'SPLIB_LIB'} || '-L../.. -L../spread-src-3.17.0/' ;
$SPLIB_INCLUDE = $ENV{'SPLIB_INCLUDE'} || '-I ../.. -I ../spread-src-3.17.0/' ;

WriteMakefile(
	NAME		=> 'Spread',
	VERSION_FROM	=> 'Spread.pm',
	LIBS		=> [ "$SPLIB_LIB -lspread" ],
	INC		=> " $SPLIB_INCLUDE" ,
	dist		=> { COMPRESS => 'gzip -9f',
			     SUFFIX => 'gz', },
	);
