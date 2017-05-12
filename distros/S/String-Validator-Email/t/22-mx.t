#!perl -T

use Test::More tests => 10;

BEGIN {
    use_ok( 'String::Validator::Email' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Email $String::Validator::Email::VERSION, Perl $], $^X" );

note( 'Check that the mx check option is working.' );
my $Validator = String::Validator::Email->new(
        mxcheck => 1 ) ;

#Useful only for author debugging.
my %switchhash = %{$Validator->{ switchhash }} ;
my @keys = keys %switchhash ;
my @values = values %switchhash ;
note( "Keys    @keys" ) ;
note( "Values  @values" ) ;

like ( $Validator->IsNot_Valid( 'bad@email' ), qr /fqdn/,
	'bad@email Should have returned fqdn error.' ) ;
is( $Validator->Check( 'bad@fake11.subd0ma1n.cpan.org' ),
	1, "This address should pass all except mxcheck" ) ;
like( $Validator->Errstr, qr/MX/, 'Errstr tells us No MX.' ) ;
is( $Validator->Is_Valid( 'brainbuz@brainbuz.org' ),
	1, "brainbuz.org If my email address isn\'t valid no one is maintaining this module!" ) ;
note( $Validator->Expound() ) ;
cmp_ok( length($Validator->Errstr), '==', 0, 'Errstr should be empty.' ) ;

is( $Validator->Is_Valid( 'brainbuz@gmail.com' ),
	1, "gmail If my email address isn\'t valid no one is maintaining this module!" ) ;
note( $Validator->Expound() ) ;

is( $Validator->Is_Valid( 'brainbuz@ghost7mail.com' ),
	0, "ghost7mail.com made up address Is_Valid returns false" ) ;
like( $Validator->IsNot_Valid( 'brainbuz@ghost7mail.com' ),
	qr/MX/, 
	"ghost7mail.com made up address IsNot_Valid returns reason of MX" ) ;
like( $Validator->Expound(),
	qr/Mail Exchanger for ghost7mail.com is missing/, 
	"Expounding after previous test tells us Mail Exchanger for ghost7mail.com is missing." ) ;	

done_testing() ;


