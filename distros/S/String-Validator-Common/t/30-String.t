#!perl -T

use Test::More tests => 5;

BEGIN {
    use_ok( 'String::Validator::Common' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Common $String::Validator::Common::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Common->new() ;

is ( $Validator->String(), '',
	'This is a new Validator and has no value for String.') ;

$Validator->IsNot_Valid( 'aBC123*', 'aBC123*' );
is ( $Validator->String(), 'aBC123*', 'Returns the last string.') ;

$Validator->Is_Valid( 'abcde' );
is ( $Validator->String(), 'abcde',
	'abcde is the last string evaluated and is returned even though it failed to validate.') ;

$Validator->Check( 'aBC123*', '1234567689' ) ;
is ( $Validator->String(), '',
	'The only time it won\'t return the last string passed is Password Mismatch.') ;

done_testing();