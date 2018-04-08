#!perl -T

use Test::More ;#tests => 1;

BEGIN {
    use_ok( 'String::Validator::Phone::NANP' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Phone::NANP $String::Validator::Phone::NANP::VERSION, Perl $], $^X" );


my $Validator = String::Validator::Phone::NANP->new( alphanum => 0 ) ;

is ( $Validator->Is_Valid( '000.418.1440' ) , 0,
    '000.418.1440 has an invalid area code.' ) ;
like ( $Validator->Errstr(), qr/non-existent Area Code/, 'bad area code.' ) ;

is ( $Validator->Is_Valid( 'Buttercup7-3456' ) , 0,
    'Buttercup7-3456 was valid until 10 digit dialing' ) ;
like ( $Validator->Errstr(), qr/Not a 10 digit Area-Number/, 'not a 10 digit number.' ) ;

done_testing() ;