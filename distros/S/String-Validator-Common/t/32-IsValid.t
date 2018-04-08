#!perl -T

use Test::More;# tests => 4;
# use Carp::Always;
use Data::Printer;

BEGIN {
    use_ok( 'String::Validator::Common' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Common $String::Validator::Common::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Common->new() ;
is( $Validator->isa('String::Validator::Common'), 1 ,  'New validator isa String::Validator::Common' ) ;

is ( $Validator->is_valid( 'aBC123*', 'aBC123*' ), 1,
	'A simple string that passes the default rules' ) ;
is( $Validator->string(), 'aBC123*', 'confirm internal string is the value we just checked');
is ( $Validator->Is_Valid( 'aBC123*', '1234567689' ), 0,
	'Mismatched strings fail.' ) ;
is( $Validator->string, '' , 'Running a failure after a success should leave an empty string' );

done_testing();