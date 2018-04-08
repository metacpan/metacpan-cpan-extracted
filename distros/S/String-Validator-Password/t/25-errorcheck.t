#!perl -T

use Test::More ;#tests => 11;

BEGIN {
    use_ok( 'String::Validator::Password' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Password $String::Validator::Password::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Password->new(
	min_types => 3, deny_punct => 1, max_len => 9 ) ;
note('Testing with these values:
min_types => 3, deny_punct => 2, max_len => 9 ') ;
is( $Validator->isa('String::Validator::Password'), 1 ,  'Created new String::Validator::Password.' ) ;
my $string = qq /aBcD*123/ ;
is ( $Validator->Check( $string, $string ), 1,
	"$string has 8 chars all types, but only 1 is punct, FAIL." ) ;$string = qq /aBcD^*123/ ;
is ( $Validator->Check( $string, $string ), 1,
 	"$string has 9 chars all types, 2 punct, FAIL." ) ;

$string = qq /aBcD^&*123/ ;
is ( $Validator->Check( $string, $string ), 2,
	"$string has 10 chars all types, 3 punct, FAIL with 2 Errors." ) ;
like( 	$Validator->Errstr(),
		qr/Does not meet requirement: Max Length 9/,
		'The error string should tell us it is too long.') ;
note( $Validator->errstr );
like( 	$Validator->Errstr(),
		qr/character type punct is prohibited/,
		'punct is prohibited' ) ;
is( $Validator->Errcnt() , 2, 'Check the errcnt method for 2 errors.') ;


done_testing;
=pod


# Coverage Test force opposite branch
is ( $Validator->Check( $string, "$string$string" ), 2,
	"$string has 10 chars all types, 3 punct, FAIL with 2 Errors." ) ;

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
	deny_num => 1,
	require_lc => 2,
	require_uc => 2,
	max_len => 10 ') ;
$string = qq /ABCde123/ ;
is ( $Validator->Check( $string, $string ), 1,
	"$string has 8 chars no punct, but only 2 are num, FAIL." ) ;
$string = qq /aBCD^*12345/ ;
is ( $Validator->Check( $string, $string ), 4,
	"$string is too long, has punct and two many digits not enoug uc, FAIL with 4." ) ;

done_testing();