#!perl -T
# String Validator Common.

use Test::More tests => 4;

BEGIN {
    use_ok( 'String::Validator::Common' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Common $String::Validator::Common::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Common->new() ;

is ( $Validator->Start( 'snargle@snugg.com', 'snargle@snugg.com' ), 0,
	'Matching strings pass.' ) ;
#print $Validator->{ errstring }, "\n" ;


is ( $Validator->Start( 'aBC123@123.net', '1234567@689.org' ), 99,
	'Mismatched strings fail.' ) ;
is ( $Validator->CheckCommon( 'aBC123@123.net', '1234567@689.org' ), 1,
	'The same test as previous using CheckCommon.' ) ;

#done_testing();