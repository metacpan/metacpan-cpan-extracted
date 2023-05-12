#!perl

use Test::More ;
use String::Validator::Password 1.90;

diag( "Testing String::Validator $String::Validator::VERSION, Perl $], $^X" );
use_ok( String::Validator::Language::FR );
use_ok( String::Validator::Common);

my $Validator = String::Validator::Password->new(
		min_len => 6,
		max_len => 32,
		language => String::Validator::Language::FR->new(),
		) ;

ok( String::Validator::Language::FR->new(),
	'coverage test -- true value returned by new method' );
like( $Validator->IsNot_Valid( 'fish'), qr/Ne respecte pas la longeur minimale imposée 6/,
	'test an invalid string and expect the error in french.'
	);

$Validator = String::Validator::Password->new(
	min_types => 3, deny_punct => 1, max_len => 9,
	language => String::Validator::Language::FR->new(),
	) ;

$string = qq /aBcD^&*123/ ;
is ( $Validator->Check( $string, $string ), 2,
	"$string has 10 chars all types, 3 punct, FAIL with 2 Errors." ) ;
like( 	$Validator->Errstr(),
		qr/maximal imposée 9/,
		'The error string should tell us it is too long.') ;
note( $Validator->errstr );
like( 	$Validator->Errstr(),
		qr/Caractères de punct est interdit/,
		'punct is prohibited' ) ;
is( $Validator->Errcnt() , 2, 'Check the errcnt method for 2 errors.') ;


#   Failed test 'The error string should tell us it is too long.'
#   at t/01-fr.t line 33.
#                   ' Ne respecte pas la longueur maximal imposée 9
# Caractères de punct est interdit.
# '
#     doesn't match '(?^:Does not meet requirement: Max Length 9)'
#   Failed test 'punct is prohibited'
#   at t/01-fr.t line 37.
#                   ' Ne respecte pas la longueur maximal imposée 9
# Caractères de punct est interdit.

done_testing();