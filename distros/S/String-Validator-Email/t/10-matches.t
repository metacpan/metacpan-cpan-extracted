#!perl -T

use Test::More tests => 6;

BEGIN {
    use_ok( 'String::Validator::Email' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Email $String::Validator::Email::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Email->new() ;
is( $Validator->isa('String::Validator::Email'), 1 ,  'New validator isa String::Validator::Email' ) ;
is( $Validator->isa('String::Validator::Common'), 1 ,  'New validator isa String::Validator::Common' ) ;


is ( $Validator->CheckCommon( 'snargle@snugg.com', 'snargle@snugg.com' ), 0,
	'A simple password that passes the default rules' ) ;
#print $Validator->{ errstring }, "\n" ;

is ( $Validator->CheckCommon( 'aBC123@123.net', '1234567@689.org' ), 1,
	'Mismatched passwords fail.' ) ;
is ( $Validator->Check( 'aBC123@123.net', '1234567@689.org' ), 1,
	'Mismatched addresses fail via the Check Method.' ) ;	
done_testing();