#!perl -T

use Test::More tests => 18;

BEGIN {
    use_ok( 'String::Validator::Password' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Password $String::Validator::Password::VERSION, Perl $], $^X" );

# Test with just default values.
my $Validator = String::Validator::Password->new() ;
is( $Validator->isa('String::Validator::Password'), 1 ,  'New validator isa String::Validator::Password' ) ;

is ( $Validator->Check( 'aBC123*', 'aBC123*' ), 0,
	'A simple password that passes the default rules.' ) ;
note( 'Checking against default min_types and check internal counters for types.') ;
is ( $Validator->IsNot_Valid( '1234567689' ),
	"1 types were found, 2 required.\n" , 	'1234567689 fails types.' ) ;
note( "last test types found $Validator->{ types_found }" ) ;

is ( $Validator->{ types_found }, 1, 'Internal num_types counter should be 1.' ) ;
is ( $Validator->{ num_num }, 10, 'Internal num_num counter should be 10. ' ) ;
is ( $Validator->{ num_lc }, 0, ' num_lc counter should be 0. ' ) ;
is ( $Validator->{ num_uc } , 0, ' num_uc counter should be 0. ' ) ;
is ( $Validator->{ num_punct }, 0, ' num_punct counter should be 0. ' ) ;
is ( $Validator->Check( '123456768X' ), 0, 	'1234567689X passes types.' ) ;
is ( $Validator->Check( '123456768z' ), 0, 	'1234567689z passes types.' ) ;
is ( $Validator->Check( '123456768^' ), 0, 	'1234567689^ passes types.' ) ;

note('Checking length') ;
is ( $Validator->Check( 'Short' ), 1, 	'Short is too short.' ) ;
like( 	$Validator->{ errstring },
		qr/Length of 5 Does not meet requirement/,
		'The error string should tell us it is too short.') ;
#print "******\n", $Validator->{ errstring }, "\n************\n" ;

is ( $Validator->Check( 'SlartibartifastoriousIS31chrLNG'), 0, '31 character string passes.') ;
is ( $Validator->Check( 'SlartibartifastoriousIS32chrL)NG'), 0, '32 character string passes.') ;
is ( $Validator->Check( 'SlartibartifastoriousIS0ch^rL)NGSlartibartifastoriousIS65ch^rL)NG'), 1, '33 character string fails.') ;
like( 	$Validator->{ errstring },
		qr/Length of 65 Does not meet requirement/,
		'The error string should tell us it is too long.') ;

done_testing();