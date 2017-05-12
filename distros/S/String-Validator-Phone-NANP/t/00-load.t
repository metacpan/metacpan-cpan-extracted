#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'String::Validator::Phone::NANP' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Phone::NANP $String::Validator::Phone::NANP::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Phone::NANP->new( alphanum => 1 ) ;
is( $Validator->isa( 'String::Validator::Phone::NANP' ), 1,
	'Created a String::Validator::Phone::NANP object' ) ;
is( $Validator->isa( 'String::Validator::Common' ), 1,
	'Object is also a String::ValidatorCommon' ) ;