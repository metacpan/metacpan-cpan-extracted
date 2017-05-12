#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'String::Validator::Email' ) || print "Bail out!\n";
}
my $Validator = String::Validator::Email->new() ;
is( $Validator->isa('String::Validator::Email'), 1 ,  'New validator isa String::Validator::Email' ) ;
is( $Validator->isa('String::Validator::Common'), 1 ,  'New validator isa String::Validator::Common' ) ;

diag( "Testing String::Validator::Email $String::Validator::Email::VERSION, Perl $], $^X" );
