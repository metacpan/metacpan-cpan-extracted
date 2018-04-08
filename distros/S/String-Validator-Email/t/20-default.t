#!perl -T

use Test::More tests => 14;

BEGIN {
    use_ok( 'String::Validator::Email' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Email $String::Validator::Email::VERSION, Perl $], $^X" );

my $Validator = String::Validator::Email->new() ;

my $result = $Validator->Check( 'bad@email' ) ;
is ( $result, 1, 'Should have returned 1 error' ) ;
like ( $Validator->Errstr , qr /fqdn/, 'bad@email Error String should include fqdn.' ) ;

$result = $Validator->Check( 'bad-at-email.domain' ) ;
is ( $result, 1, 'Should have returned 1 error' ) ;
like ( $Validator->Errstr , qr /rfc822/, "bad-at-email.domain Error String should include rfc822." ) ;

# Useful only for author debugging.
# my %switchhash = %{$Validator->{ switchhash }} ;
# my @keys = keys %switchhash ;
# my @values = values %switchhash ;
# note( "Keys    @keys" ) ;
# note( "Values  @values" ) ;

$result = $Validator->Check( 'bad@email.fakedomain' ) ;
is ( $result, 1, 'Should have returned 1 error' ) ;


like ( $Validator->Errstr , qr /tldcheck/,
	"bad\@email.fakedomain Error String should include tldcheck." ) ;
like ( $Validator->Expound() , qr /Top Level Domain.+not recognized/ ,
        'Expound tells us it didnt recognize tld.') ;

is( $Validator->Is_Valid( 'my.account@[192.168.1.1]' ),
        0, 'IP address not allowed for domain.' ) ;
# TODO: {
        local $TODO = 'Need to replace Email::Valid for now skip tests.' ;
like ( $Validator->Expound() , qr /The TLD/ ,
        'Expound tells us it didnt recognize tld.') ;
# } #TODO
#note ( 'Internal String ' . $Validator->{ string } ) ;
#note ( 'Error String ' . $Validator->{ errstring } ) ;
 ;
is( $Validator->Check( 'aloitious@algonquin.com' ) ,
    0 , "This string should be ok." ) ;
is( $Validator->Check( 'aloitious@thealgonquin' ) , 1 ,
        "This string should not be ok. but the error should not be fatal." ) ;
like( $Validator->Errstr() , qr/fqdn/,
        "aloitious\@thealgonquin Failed for fqdn." ) ;
like( $Validator->Expound() , qr/Fully Qualified Domain Name/,
        'expound method explained that it requires a Fully Qualified Domain Name' ) ;

done_testing() ;