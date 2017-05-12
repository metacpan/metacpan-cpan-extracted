#!perl -T

use Test::More ;#tests => 1;

BEGIN {
    use_ok( 'String::Validator::Phone::NANP' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Phone::NANP $String::Validator::Phone::NANP::VERSION, Perl $], $^X" );

note( "Similar tests to defaults with alpha switched on." ) ;

my $Validator = String::Validator::Phone::NANP->new( alphanum => 1 ) ;
is ( $Validator->Is_Valid( '+1 312 447 HELP' ) , 1,
    'First test is a valid phone number +1 312 447 HELP' ) ;
is ( $Validator->String(), '312-447-4357', '+1 312 447 HELP -> 312-447-4357' ) ;
is ( $Validator->Is_Valid( '201.703.T0YS' ) , 1,
    'Second test is a valid phone number in different format. 201.703.T0YS' ) ;
is ( $Validator->String(), '201-703-8097', '201.703.T0YS -> 201-703-8097' ) ;
is ( $Validator->Is_Valid( '604.CAN.ADA1' ) , 1,
    'Second test is a valid phone number in different format. 604-226-2321' ) ;
is ( $Validator->String(), '604-226-2321', '604.CAN.ADA1 -> 604-226-2321' ) ;
is ( $Validator->Is_Valid( '000.418.1440' ) , 0,
    '000.418.1440 has an invalid area code.' ) ;
like ( $Validator->Errstr(), qr/non-existent Area Code/, 'bad area code.' ) ;
done_testing() ;


#4357