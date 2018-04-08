#!perl -T
# String Validator Password

use Test::More tests => 4;

BEGIN {
    use_ok( 'String::Validator::Password' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Password $String::Validator::Password::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Password->new() ;
is( $Validator->isa('String::Validator::Password'), 1 ,  'New validator isa String::Validator::Password' ) ;

is ( $Validator->Check( 'aBC123*', 'aBC123*' ), 0,
	'A simple password that passes the default rules' ) ;

is ( $Validator->Check( 'aBC123*', '1234567689' ), 1,
	'Mismatched passwords fail.' ) ;
done_testing();