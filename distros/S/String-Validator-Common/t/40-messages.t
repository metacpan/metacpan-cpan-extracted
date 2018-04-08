#!perl
# String Validator Common.

# Test that messages can be over-ridden.

package FRENCH;

	sub new {
		return {
		        common_strings_not_match => 'Les chaînes de caractères ne correspondent pas.',
		        common_tooshort => " Ne respecte pas la longeur minimale imposée ",
		        common_toolong =>  " Ne respecte pas la longueur maximal imposée ",
		}
	}

package Main;

use Test::More tests => 6;
use Data::Printer;

BEGIN {
    use_ok( 'String::Validator::Common' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Common $String::Validator::Common::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Common->new(
	max_len => 7,
	language => {
		        common_strings_not_match => 'I haz different strings',
		        common_tooshort => " Strin iz 2 short  ",
		        common_toolong =>  " Strin iz 2 long ",},
	custom_messages => {
		lolcat_hungry => 'I haz cheeseburger'}
) ;

is ( $Validator->Start( 'aBC123@123.net', '1234567@689.org' ), 99,
	'Mismatched strings fail.' ) ;
like( 	$Validator->Errstr(),
		qr/I haz different strings/,
		'The error string should tell us it is too short, in LOLCat.') ;

$Validator->CheckCommon( 'snargle@snugg.com', 'snargle@snugg.com') ;

like( 	$Validator->Errstr(),
		qr/Strin iz 2 long /,
		'the next error is too long, in LOLCat.') ;

my $expected_lol_messages =  {
    common_strings_not_match => "I haz different strings",
    common_toolong           => " Strin iz 2 long ",
    common_tooshort          => " Strin iz 2 short  ",
    lolcat_hungry            => "I haz cheeseburger"
} ;

is_deeply( $Validator->{messages} , $expected_lol_messages,
	"Internal messages in Validator matches the list of expected messages");

my $FrenchValidator = String::Validator::Common->new(
	language => FRENCH->new(),
);

my $expected_fr_messages = {
		        common_strings_not_match => 'Les chaînes de caractères ne correspondent pas.',
		        common_tooshort => " Ne respecte pas la longeur minimale imposée ",
		        common_toolong =>  " Ne respecte pas la longueur maximal imposée ",
		};

is_deeply( $FrenchValidator->{messages}, $expected_fr_messages,
	'Confirm that the internal messages match those from a package of French messages');
