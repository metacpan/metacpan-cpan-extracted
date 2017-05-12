#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'String::Validator::Common' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Common $String::Validator::Common::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Common->new() ;
is( $Validator->isa('String::Validator::Common'), 1 ,  'New validator isa String::Validator::Common' ) ;

is ( $Validator->IsNot_Valid( 'aBC123*', 'aBC123*' ), 0,
	'A simple string that passes the default rules' ) ;
#print $Validator->{ errstring }, "\n" ;

is ( $Validator->Check( 'aBC123*', '1234567689' ), 1,
	'Mismatched strings fail.' ) ;
done_testing();