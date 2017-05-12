#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'String::Validator::Password' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Password $String::Validator::Password::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Password->new() ;

is( $Validator->isa('String::Validator::Password'), 1 ,  'New validator isa String::Validator::Password' ) ;
