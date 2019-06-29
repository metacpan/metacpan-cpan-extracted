#!perl -T

use Test::More tests => 35;

BEGIN {
    use_ok( 'String::Validator::Password' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Password $String::Validator::Password::VERSION, Perl $], $^X" );

# Test with just default values.

my $lc = 'lowercaseonly' ;
my $uc = 'UPPERCASEONLY' ;
my $numeric = '103204232' ;
my $allpunct = ')(#!@(^&#_*&^#;:<>' ;
my $oneofeach ='aA1!' ;
my $twoofeach ='aA1!Bb#2' ;

note( 'Deny_lc.') ;
my $Validator = String::Validator::Password->new(
	deny_lc => 1 , min_types => 0 , min_len => 0 ) ;
is ( $Validator->Check( $lc ), 1, 'lowercaseonly string  rejected.' ) ;
is ( $Validator->Check( $uc ), 0, 'UPPERCASEONLY string accepted.' ) ;
is ( $Validator->Check( $numeric ), 0, 'numeric string accepted.' ) ;
is ( $Validator->Check( $allpunct ), 0, 'allpunct string accepted.' ) ;
is ( $Validator->Check( $oneofeach ), 1, 'oneofeach string rejected.' ) ;
is ( $Validator->Check( $twoofeach ), 1, 'twoofeach string rejected' ) ;

note( 'Deny_uc.') ;
$Validator = String::Validator::Password->new(
	deny_uc => 1 , min_types => 0 , min_len => 0 ) ;
is ( $Validator->Check( $lc ), 0, 'lowercaseonly string  accepted.' ) ;
is ( $Validator->Check( $uc ), 1, 'UPPERCASEONLY string rejected.' ) ;
is ( $Validator->Check( $numeric ), 0, 'numeric string accepted.' ) ;
is ( $Validator->Check( $allpunct ), 0, 'allpunct string accepted.' ) ;
is ( $Validator->Check( $oneofeach ), 1, 'oneofeach string rejected.' ) ;
is ( $Validator->Check( $twoofeach ), 1, 'twoofeach string rejected' ) ;


note( 'Deny_nums.') ;
$Validator = String::Validator::Password->new(
	require_num => 1 , min_types => 0 , min_len => 0 ) ;
is ( $Validator->Check( $lc ), 1, 'lowercaseonly string  fails.' ) ;
is ( $Validator->Check( $uc ), 1, 'UPPERCASEONLY string fails.' ) ;
is ( $Validator->Check( $numeric ), 0, 'numeric string passes.' ) ;
is ( $Validator->Check( $allpunct ), 1, 'allpunct string fails.' ) ;
is ( $Validator->Check( $oneofeach ), 0, 'oneofeach string passes.' ) ;
is ( $Validator->Check( $twoofeach ), 0, 'twoofeach string passes' ) ;

note( 'Require_punct.') ;
# This time change the parameters in the object directly,
# as this should work. If I had chosen to use Moose I would
# have gotten a free setter method, but I chose to skip
# the dependency and am not going to write the method.
$Validator->{ require_punct } = 1 ;
$Validator->{ require_num } = 0 ;
is ( $Validator->Check( $lc ), 1, 'lowercaseonly string  fails.' ) ;
is ( $Validator->Check( $uc ), 1, 'UPPERCASEONLY string fails.' ) ;
is ( $Validator->Check( $numeric ), 1, 'numeric string fails.' ) ;
is ( $Validator->Check( $allpunct ), 0, 'allpunct string passes.' ) ;
is ( $Validator->Check( $oneofeach ), 0, 'oneofeach string passes.' ) ;
is ( $Validator->Check( $twoofeach ), 0, 'twoofeach string passes' ) ;

note( 'Deny_punct.') ;
# Check that deny punct works.
$Validator->{ require_punct } = 0 ;
$Validator->{ deny_punct } = 1 ;
is ( $Validator->Check( $twoofeach ), 1,
  'twoofeach string fails with deny_punct 1.' ) ;
$Validator->{ deny_punct } = 3 ;
is ( $Validator->Check( $twoofeach ), 0,
  'twoofeach string passes with deny_punct 3.' ) ;
diag( 'Validator found punct ' . $Validator->{num_punct} );
$Validator->{ deny_punct } = 2 ;
is ( $Validator->Check( $twoofeach ), 1,
  'twoofeach string fails with deny_punct 2.' ) ;
$Validator->{ deny_punct } = 5 ;
my $sixpunct = "\#\$\^$twoofeach ";
is ( $Validator->Check( $sixpunct ), 1,
  'sixpunct string fails with deny_punct 5.');

$Validator->{ require_punct } = 1 ;
$Validator->{ deny_punct } = 0 ;

note('Setting deny_xx to a value greater than 1 should set that as the maximum') ;
$Validator = String::Validator::Password->new(
	deny_num => 4 , min_types => 0 , min_len => 0 ) ;
is ( $Validator->Check( $numeric ), 1, 'numeric string rejected (10 digit). ' ) ;

$Validator = String::Validator::Password->new( min_types => 4 ) ;
is ( $Validator->Check( 'THREE3type' ), 1, 	'THREE3type  fails with types set to 4.' ) ;
like ( $Validator->Errstr(), qr/Input contained 3 types of character, 4 are required./,
	'Errstr: Input contained 3 types of character, 4 are required.');
# deny_nums
$Validator = String::Validator::Password->new( deny_num => 1, min_len => 5  ) ;
like ( $Validator->IsNot_Valid( 'THREE3type' ), qr/character type numeric is prohibited/,
	'Errstr: numbers are probited.');
$Validator = String::Validator::Password->new( require_num => 4, min_len => 5  ) ;
like ( $Validator->IsNot_Valid( 'NoNUMS???' ), qr/At least 4 characters of type numeric is required./,
	'Errstr: numbers are requried.');
$Validator = String::Validator::Password->new( deny_punct => 1, min_len => 5  ) ;
like ( $Validator->IsNot_Valid( 'PUNCTUAT3d!' ), qr/punct is prohibited/,
	'Errstr: punctuation is probited.');

done_testing();