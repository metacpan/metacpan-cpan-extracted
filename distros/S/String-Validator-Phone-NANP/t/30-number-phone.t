#!perl -T

use Test::More ;#tests => 1;

BEGIN {
    use_ok( 'String::Validator::Phone::NANP' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Phone::NANP $String::Validator::Phone::NANP::VERSION, Perl $], $^X" );

note( "We can create a Number::Phone::NANP object. It is tested to prove this works
and because a major todo is to completely encapsulate Number::Phone within
String::Validator::Phone." ) ;

# Number/Original - country - areacode
my @Stringset = (
 [ '+1 202 418 1440', 'US', '202' ],
 [ '1 (212) MU7-WXYZ' , 'US', '212' ],
 [ '415-AKA-THEM' , 'US', '415' ],
 [ '609-234-5678', 'US',  '609' ],
 [ '441-323-3451', 'BM' , '441' ] ,
 [ '416-323-3451', 'CA' , '416' ] ,
    ) ;

my $Validator = String::Validator::Phone::NANP->new( alphanum => 1 ) ;

foreach my $string ( @Stringset ) {
	my ( $original, $country, $areacode ) =	@{$string} ;
	$Validator->IsNot_Valid( $original ) ;
	my $Phone = $Validator->Number_Phone() ;
	note( "Testing phone object creation for $original" ) ;
	is( $Phone->isa( 'Number::Phone::NANP' ), 1,
			'Created a Number::Phone::NANP object' ) ;
	is( $Phone->is_valid, 1, "$original Number_Phone is_valid should be true." ) ;
	is( $Phone->areacode, $areacode, "$original areacode." ) ;
	is( $Phone->country, $country, "$original Country: $country" ) ;
}

is( $Validator->isnot_valid( '415-AKA-THEM' ), 0,
	'test isnot_valid against alphanumeric number' );
is( $Validator->Exchange(), 252, 'read translated exchange');

my $bad = '221-321-ABC' ;
is ( $Validator->Is_Valid( $bad ), 0 , "$bad fails Is_Valid") ;
is ( $Validator->Number_Phone(), 0 ,
	"After $bad cannot create a Number::Phone object.") ;
like( $Validator->isnot_valid( '221-321-ABC', '672-662-1212' ),
	qr/Strings don\'t match/, 'mismatched strings will always fail');

done_testing() ;


#4357