#!perl -T

use Test::More ;#tests ; #=> 6;

BEGIN {
    use_ok( 'String::Validator::Common' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Common $String::Validator::Common::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Common->new() ;
is( $Validator->isa('String::Validator::Common'), 1 ,  'New validator isa String::Validator::Common' ) ;

note( 'Testing Method IsNot_Valid') ;

is ( $Validator->IsNot_Valid( 'aBC123*', 'aBC123*' ), 0,
	'A simple string that passes the default rules' ) ;
is ( $Validator->Errcnt, 0, 'Error Count should be 0 too.' );

like ( $Validator->IsNot_Valid( 'aBC123*', '1234567689' ),
	qr /Strings don't match/, 'Mismatched strings fail.' ) ;
is ( $Validator->Errcnt, 1, 'Error Count should be 1 after the fail.' );
like ( $Validator->Errstr, qr /Strings don't match/, 'Errstr method returns the same string.' );


done_testing();