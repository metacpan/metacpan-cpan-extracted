#!perl -T

#use Test::More tests => 1;
use Test::More ;

diag( "Testing String::Validator $String::Validator::VERSION, Perl $], $^X" );
#ok( $validator = String::Validator->new(), 'create a string validator object') ;
use_ok( 'String::Validator::Password' );

done_testing();