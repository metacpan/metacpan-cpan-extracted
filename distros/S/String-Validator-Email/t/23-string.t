#!perl -T

use Test::More ;#tests ;#=> 12;

BEGIN {
    use_ok( 'String::Validator::Email' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Email $String::Validator::Email::VERSION, Perl $], $^X" );

note( 'Check stringification.' );
my $Validator = String::Validator::Email->new() ;

is( $Validator->IsNot_Valid( 'Jane Brown <jane.brown@domain.com>' ), 0 ,
	'Jane Brown <jane.brown@domain.com> contains a valid email address' ) ;
note( $Validator->String() ) ;

is( $Validator->{ maildomain }, 'domain.com', 
		"Even for this bad address Validator should know domain part is domain.com" );

done_testing() ;


