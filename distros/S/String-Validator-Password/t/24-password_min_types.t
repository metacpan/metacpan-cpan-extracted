#!perl -T

use Test::More tests => 20;

BEGIN {
    use_ok( 'String::Validator::Password' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Password $String::Validator::Password::VERSION, Perl $], $^X" );

#Testing changing parameters.
# NumTypes
note('Changing the min_types parameter') ;
note('min_types 0 means that even a null string would pass this test') ;
my $Validator = String::Validator::Password->new( min_types => 0 , min_len => 0 ) ;
is ( $Validator->Check( '1234567689' ), 0, 	'1234567689 still passes with types set to 0.' ) ;
is ( $Validator->Check( '' ), 0, 	'With min_len 0 a null string passes.' ) ;
note('Testing with min_types = 1' ) ;
$Validator = String::Validator::Password->new( min_types => 1 ) ;
is ( $Validator->Check( '1234567689' ), 0, 	'1234567689 passes with types set to 1.' ) ;
is ( $Validator->Check( 'has2types2' ), 0, 	'has2types2 passes with types set to 1.' ) ;
is ( $Validator->Check( 'THREE3type' ), 0, 	'THREE3type passes with types set to 1.' ) ;
is ( $Validator->Check( 'FOUR>4type' ), 0, 	'FOUR>4type passes with types set to 1.' ) ;
note('Testing with min_types = 2.' ) ;
$Validator = String::Validator::Password->new( min_types => 2 ) ;
is ( $Validator->Check( '1234567689' ), 1, 	'1234567689 fails  with types set to 2.' ) ;
is ( $Validator->Check( 'has2types2' ), 0, 	'has2types2 passes with types set to 2.' ) ;
is ( $Validator->Check( 'THREE3type' ), 0, 	'THREE3type passes with types set to 2.' ) ;
is ( $Validator->Check( 'FOUR>4type' ), 0, 	'FOUR>4type passes with types set to 2.' ) ;
$Validator = String::Validator::Password->new( min_types => 3 ) ;
is ( $Validator->Check( '1234567689' ), 1, 	'1234567689 fails  with types set to 3.' ) ;
is ( $Validator->Check( 'has2types2' ), 1, 	'has2types  fails  with types set to 3.' ) ;
is ( $Validator->Check( 'THREE3type' ), 0, 	'THREE3type passes with types set to 3.' ) ;
is ( $Validator->Check( 'FOUR>4type' ), 0, 	'FOUR>4type passes with types set to 3.' ) ;
note('Testing with min_types = 2.' ) ;
$Validator = String::Validator::Password->new( min_types => 4 ) ;
is ( $Validator->Check( '1234567689' ), 1, 	'1234567689  fails with types set to 4.' ) ;
is ( $Validator->Check( 'has2types2' ), 1, 	'has2types2  fails with types set to 4.' ) ;
is ( $Validator->Check( 'THREE3type' ), 1, 	'THREE3type  fails with types set to 4.' ) ;
like ( $Validator->Errstr(), qr/Input contained 3 types of character, 4 are required./,
	'Errstr: Input contained 3 types of character, 4 are required.');
is ( $Validator->Check( 'FOUR>4type' ), 0, 	'FOUR>4type passes with types set to 4.' ) ;


done_testing();