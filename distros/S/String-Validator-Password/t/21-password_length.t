#!perl -T

use Test::More tests => 14;

BEGIN {
    use_ok( 'String::Validator::Password' ) || print "Bail out!\n";
}
diag( "Testing String::Validator::Password $String::Validator::Password::VERSION, Perl $], $^X" );


my $Validator = String::Validator::Password->new( max_len => 32 ) ;
note('Checking length') ;
is ( $Validator->Check( 'Short' ), 1, 	'Short is too short.' ) ;
like( 	$Validator->{ errstring },
		qr/Length of 5 Does not meet requirement/,
		'The error string should tell us it is too short.') ;
#print "******\n", $Validator->{ errstring }, "\n************\n" ;

is ( $Validator->Check( 'SlartibartifastoriousIS31chrLNG'), 0, '31 character string passes.') ;
is ( $Validator->Check( 'SlartibartifastoriousIS32chrL)NG'), 0, '32 character string passes.') ;
is ( $Validator->Check( 'SlartibartifastoriousIS33ch^rL)NG'), 1, '33 character string fails.') ;
like( 	$Validator->{ errstring },
		qr/Length of 33 Does not meet requirement/,
		'The error string should tell us it is too long.') ;
$Validator->{ min_len } = 22 ;
note('min_len now 22');
#print $Validator->{ min_len }, "********************\n" ;
is ( $Validator->Check( 'Sl@rtib!rtIS22chrsLONG'), 0, '22 character string PASS.') ;
is ( $Validator->Check( 'Sl@rtib!rtIS23+chrsLONG'), 0, '23 character string Pass.') ;
is ( $Validator->Check( 'Sl@rtib!rtIS19+chrs'), 1, '19 character string FAIL.') ;
like( 	$Validator->{ errstring },
		qr/Length of 19 Does not meet requirement: Min Length/,
		'The error string should tell us it is too long.') ;

$Validator->{ max_len } = 22 ;
note('max and min length are now both 22') ;
is ( $Validator->Check( 'Sl@rtib!rtIS23+chrsLONG'), 1, '23 character string Fail.') ;
is ( $Validator->Check( 'Sl@rtib!rtIS22chrsLONG'), 0, '22 character string PASS.') ;
is ( $Validator->Check( 'Sl@rtib!rtIS21##+chrs'), 1, '21 character string FAIL.') ;



done_testing();