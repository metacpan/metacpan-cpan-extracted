#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'String::Validator::Common' ) || print "Bail out!\n";
}
my $Validator = String::Validator::Common->new() ;
is( $Validator->isa('String::Validator::Common'), 1 ,  'New validator isa String::Validator::Common' ) ;
diag( "Testing String::Validator::Common $String::Validator::Common::VERSION, Perl $], $^X" );
