#!perl -T

use Test::More tests => 11;

BEGIN {
    use_ok( 'String::Validator::Password' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Password $String::Validator::Password::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Password->new(
	min_types => 3, deny_punct => 2, max_len => 9 ) ;
note('Testing with these values:
min_types => 3, deny_punct => 2, max_len => 9 ') ;
is( $Validator->isa('String::Validator::Password'), 1 ,  'Created new String::Validator::Password.' ) ;

my $string = qq /aBcD*123/ ;
is ( $Validator->Check( $string, $string ), 0,
	"$string has 8 chars all types, but only 1 is punct, PASS." ) ;
$string = qq /aBcD^*123/ ;
is ( $Validator->Check( $string, $string ), 1,
 	"$string has 9 chars all types, 2 punct, FAIL." ) ;
$Validator->{ deny_punct } = 3 ;
note('Raise punct limit to 3 to permit 2 puncts in previous string') ;
is ( $Validator->Check( $string, $string ), 0,
 	"$string PASS with limit raised to 3." ) ;
$string = qq /aBcD^&*123/ ;
is ( $Validator->Check( $string, $string ), 2,
	"$string has 10 chars all types, 3 punct, FAIL with 2 Errors." ) ;
note( $Validator->Errstr() ) ;

like( 	$Validator->Errstr(),
		qr/Length of 10 Does not meet requirement/,
		'The error string should tell us it is too long.') ;
like( 	$Validator->Errstr(),
		qr/punct is limited to fewer than 3/,
		'punct is limited to fewer than 3' ) ;
is( $Validator->Errcnt() , 2, 'Check the errcnt method for 2 errors.') ;

$Validator = String::Validator::Password->new(
	min_types => 2,
	deny_punct => 1,
	deny_num => 4,
	require_lc => 2,
	require_uc => 2,
	max_len => 10 ) ;
note('Testing with these values:
	min_types => 2,
	deny_punct => 1,
	deny_num => 4,
	require_lc => 2,
	require_uc => 2,
	max_len => 10 ') ;
$string = qq /ABCde123/ ;
is ( $Validator->Check( $string, $string ), 0,
	"$string has 8 chars no punct, but only 2 are num, PASS." ) ;
$string = qq /aBCD^*12345/ ;
is ( $Validator->Check( $string, $string ), 4,
	"$string is too long, has punct and two many digits not enoug uc, FAIL with 4." ) ;

done_testing();