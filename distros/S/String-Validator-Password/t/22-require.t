#!perl -T

use Test::More tests => 29 ;

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

note( 'Require_lc.') ;
my$Validator = String::Validator::Password->new(
	require_lc => 1 , min_types => 0 , min_len => 0 ) ;
is ( $Validator->Check( $lc ), 0, 'lowercaseonly string  passes.' ) ;
is ( $Validator->Check( $uc ), 1, 'UPPERCASEONLY string fails.' ) ;
is ( $Validator->Check( $numeric ), 1, 'numeric string fails.' ) ;
is ( $Validator->Check( $allpunct ), 1, 'allpunct string fails.' ) ;
is ( $Validator->Check( $oneofeach ), 0, 'oneofeach string passes.' ) ;
is ( $Validator->Check( $twoofeach ), 0, 'twoofeach string passes' ) ;

note( 'Require_uc.') ;
$Validator = String::Validator::Password->new(
	require_uc => 1 , min_types => 0 , min_len => 0 ) ;
is ( $Validator->Check( $lc ), 1, 'lowercaseonly string  fails.' ) ;
is ( $Validator->Check( $uc ), 0, 'UPPERCASEONLY string passes.' ) ;
is ( $Validator->Check( $numeric ), 1, 'numeric string fails.' ) ;
is ( $Validator->Check( $allpunct ), 1, 'allpunct string fails.' ) ;
is ( $Validator->Check( $oneofeach ), 0, 'oneofeach string passes.' ) ;
is ( $Validator->Check( $twoofeach ), 0, 'twoofeach string passes' ) ;

note( 'Require_nums.') ;
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

note('Setting a require to a number greater than 1 sets that as a floor.') ;
$Validator = String::Validator::Password->new(
	require_num => 4 , require_punct => 4,
	min_types => 0 , min_len => 0 ) ;
is ( $Validator->Check( '@()\'*^1234' ), 0 ,
	'require 4 nums 4 punct @()\'*^1234 Passes.' ) ;
is ( $Validator->Check( '@()\'*^1234abc' ), 0 ,
	'require 4 nums 4 punct @()\'*^1234abc Passes.' ) ;
$Validator = String::Validator::Password->new(
	require_num => 4 , require_punct => 4, deny_lc => 1,
	min_types => 0 , min_len => 0 ) ;
is ( $Validator->Check( '@()\'*^1234' ), 0 ,
	'require 4 nums 4 punct + deny lc @()\'*^1234 Passes.' ) ;
is ( $Validator->Check( '@()\'*^1234abc' ), 1 ,
	'require 4 nums 4 punct + deny lc @()\'*^1234abc Fails.' ) ;

done_testing();