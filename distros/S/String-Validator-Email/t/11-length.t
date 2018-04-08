#!perl -T

use Test::More tests => 16;

BEGIN {
    use_ok( 'String::Validator::Email' ) || print "Bail out!\n";
}
diag( "Testing String::Validator::Email $String::Validator::Email::VERSION, Perl $], $^X" );


my $Validator = String::Validator::Email->new(
		max_len => 32 ,
		looks_like_email => 0 , ) ;
# Looks like email needs to be off because our length test strings
# aren't valid passwords.
note('Checking length') ;
is ( $Validator->CheckCommon( 'Short' ), 1, 	'Short is too short.' ) ;
like( 	$Validator->{ errstring },
		qr/Does not meet requirement/,
		'The error string should tell us it is too short.') ;
#print "******\n", $Validator->{ errstring }, "\n************\n" ;

is ( $Validator->CheckCommon( 'SlartibartifastoriousIS31chrLNG'), 0, '31 character string passes.') ;
is ( $Validator->CheckCommon( 'SlartibartifastoriousIS32chrL)NG'), 0, '32 character string passes.') ;
is ( $Validator->CheckCommon( 'SlartibartifastoriousIS33ch^rL)NG'), 1, '33 character string fails.') ;
like( 	$Validator->{ errstring },
		qr/Does not meet requirement: Max Length 32/,
		'The error string should tell us it is too long.') ;
$Validator->{ min_len } = 22 ;
note('min_len now 22');
#print $Validator->{ min_len }, "********************\n" ;
is ( $Validator->CheckCommon( 'Sl@rtib!rtIS22chrsLONG'), 0, '22 character string PASS.') ;
is ( $Validator->CheckCommon( 'Sl@rtib!rtIS23+chrsLONG'), 0, '23 character string Pass.') ;
is ( $Validator->CheckCommon( 'Sl@rtib!rtIS19+chrs'), 1, '19 character string FAIL.') ;
like( 	$Validator->{ errstring },
		qr/Min Length 22/,
		'The error string should tell us it is too long.') ;

$Validator->{ max_len } = 22 ;
note('max and min length are now both 22') ;
is ( $Validator->CheckCommon( 'Sl@rtib!rtIS23+chrsLONG'), 1, '23 character string Fail.') ;
is ( $Validator->CheckCommon( 'Sl@rtib!rtIS22chrsLONG'), 0, '22 character string PASS.') ;
is ( $Validator->CheckCommon( 'Sl@rtib!rtIS21##+chrs'), 1, '21 character string FAIL.') ;

note( 'Check that setting both lenght vals to 0 turns the tests off.') ;
$Validator->{ max_len } = 0 ; $Validator->{ min_len } = 0  ;
is ( $Validator->CheckCommon( ''), 0, 'Null string passes when we dont check it.') ;
is ( $Validator->CheckCommon( 'slartibartfast@magrathea.planet'), 0, 'A long address in fake tld is also passing.') ;




done_testing();