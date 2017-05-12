#!perl -T

use Test::More tests => 16;

BEGIN {
    use_ok( 'String::Validator::Common' ) || print "Bail out!\n";
}
diag( "Testing String::Validator::Common $String::Validator::Common::VERSION, Perl $], $^X" );


my $Validator = String::Validator::Common->new(
		min_len => 6,
		max_len => 32, ) ;
note('Checking length') ;
$Validator->Start( 'Short' ) ;
is ( $Validator->Length(), 1, 'Short is too short.' ) ;
like( 	$Validator->Errstr(),
		qr/Length of 5 Does not meet requirement/,
		'The error string should tell us it is too short.') ;

note( 'Switch to the CheckCommon Method so as to not need to repeat start' ) ;

is ( $Validator->CheckCommon( 'SlartibartifastoriousIS31chrLNG'), 0, '31 character string passes.') ;
is ( $Validator->CheckCommon( 'SlartibartifastoriousIS32chrL)NG'), 0, '32 character string passes.') ;
is ( $Validator->CheckCommon( 'SlartibartifastoriousIS33ch^rL)NG'), 1, '33 character string fails.') ;
like( 	$Validator->Errstr,
		qr/Length of 33 Does not meet requirement/,
		'The error string should tell us it is too long.') ;
$Validator->{ min_len } = 22 ;
note('min_len now 22');
is ( $Validator->CheckCommon( 'Sl@rtib!rtIS22chrsLONG'), 0, '22 character string PASS.') ;
is ( $Validator->CheckCommon( 'Sl@rtib!rtIS23+chrsLONG'), 0, '23 character string Pass.') ;
is ( $Validator->CheckCommon( 'Sl@rtib!rtIS19+chrs'), 1, '19 character string FAIL.') ;
like( 	$Validator->Errstr() ,
		qr/Length of 19 Does not meet requirement: Min Length/,
		'The error string should tell us it is too long.') ;

$Validator->{ max_len } = 22 ;
note('max and min length are now both 22') ;
is ( $Validator->CheckCommon( 'Sl@rtib!rtIS23+chrsLONG'), 1, '23 character string Fail.') ;
is ( $Validator->CheckCommon( 'Sl@rtib!rtIS22chrsLONG'), 0, '22 character string PASS.') ;
is ( $Validator->CheckCommon( 'Sl@rtib!rtIS21##+chrs'), 1, '21 character string FAIL.') ;

note( 'Check that setting length vals to 0 turns the tests off.') ;
$Validator->{ max_len } = 0 ; $Validator->{ min_len } = 0  ;
is ( $Validator->CheckCommon( ''), 0, 'Null string passes when we dont check it.') ;
is ( $Validator->CheckCommon( 'slartibartfast@magrathea.planet'), 0, 'A long address in fake tld is also passing.') ;




done_testing();