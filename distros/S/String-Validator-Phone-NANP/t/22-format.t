#!perl -T

use Test::More ;#tests => 1;

BEGIN {
    use_ok( 'String::Validator::Phone::NANP' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Phone::NANP $String::Validator::Phone::NANP::VERSION, Perl $], $^X" );

note( "Several methods for String return and formatting --
 * Original() the original string passed,
 * String() returns AREA-EXCHANGE-NUMBER,
 * International() 1-AREA-EXCHANGE-NUMBER,
 * Parens() (AREA) EXCHANGE-NUMBER,
 * Areacode() AREA,
 * Local() EXCHANGE-NUMBER.
" ) ;

# Number/Original - String() - International - Parens - Areacode -Exchange - Local
my @Stringset = (
 [ '+1 202 418 1440', '202-418-1440', '1-202-418-1440', '(202) 418-1440', '202' , '418', '1440' ],
 [ '1 (212) MU7-WXYZ' , '212-687-9999',  '1-212-687-9999', '(212) 687-9999',
			'212', '687', '9999' ],
 [ '415-AKA-THEM' , '415-252-8436', '1-415-252-8436', '(415) 252-8436',
			'415', '252', '8436' ],
 [ '+1 (609) Adi-JMPT' , '609-234-5678', '1-609-234-5678',  '(609) 234-5678' ,
			'609', '234', '5678' ],
    ) ;

my $Validator = String::Validator::Phone::NANP->new( alphanum => 1 ) ;

foreach my $string ( @Stringset ) {
	my ( $original, $string, $international, $parens, $areacode, $exchange, $local ) =
			@{$string} ;
	$Validator->IsNot_Valid( $original ) ;
	is( $Validator->Original() , $original, "Original() $original" ) ;
 	is( $Validator->String() , $string, "String() $string" ) ;
 	is( $Validator->International() ,$international,
 			"International() $international" ) ;
	is( $Validator->Areacode() , $areacode , "Areacode() $areacode" ) ;
	is( $Validator->Exchange() , $exchange , "Exchange() $exchange" ) ;	
	is( $Validator->Local() , $local , "Local() $local" ) ;
	is( $Validator->Parens() , $parens , "Parens() $parens" ) ;
}

done_testing() ;


#4357