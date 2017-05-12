#!perl -T

use Test::More ;#tests => 1;

BEGIN {
    use_ok( 'String::Validator::Phone::NANP' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Phone::NANP $String::Validator::Phone::NANP::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Phone::NANP->new() ;
is ( $Validator->Is_Valid( '+1 202 418 1440' ) , 1,
    'First test is a valid phone number' ) ;
is ( $Validator->String(), '202-418-1440', 'String' ) ;
is ( $Validator->Is_Valid( '215.418.1440' ) , 1,
    'Second test is a valid phone number in different format.' ) ;
is ( $Validator->String(), '215-418-1440', 'String' ) ;
is ( $Validator->Is_Valid( '000.418.1440' ) , 0,
    '000.418.1440 has an invalid area code.' ) ;
like ( $Validator->Errstr(), qr/non-existent Area Code/, 'bad area code.' ) ;

my $bad = '221-321-ABC' ;
is ( $Validator->Check( $bad ), 1, "$bad Check has 1 error")  ;
is ( $Validator->Is_Valid( $bad ), 0, "$bad !Is_Valid")  ;
is ( $Validator->IsNot_Valid( $bad ),
	"Not a 10 digit Area-Number 221-321- .. 221321 = 6.\n",
	"$bad IsNot_Valid Not a 10 digit...") ;
is ( $Validator->String(), '', "After $bad String() is null." );
is ( $Validator->Original(), '', "After $bad Original() is null." );
is ( $Validator->International(), '', "After $bad International() is null." );

done_testing() ;