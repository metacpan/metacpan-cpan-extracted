#!perl -T

use Test::More tests => 12;

BEGIN {
    use_ok( 'String::Validator::Email' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Email $String::Validator::Email::VERSION, Perl $], $^X" );

note( 'Walk through each available non-default value singly' );
my $Validator = String::Validator::Email->new(
        tldcheck => 0 ) ;



my $result = $Validator->Check( 'bad@email' ) ;
is ( $result, 1, 'Should have returned 1 error' ) ;
like ( $Validator->Errstr , qr /fqdn/,
        'bad@email no fqdn should still fail with tldcheck off.' ) ;
$result = $Validator->IsNot_Valid( 'bad@email.domain' ) ;
is ( $result, 0, 'bad@email.domain passes because tldcheck is off.') ;

# To test allow_ip tldcheck must be turned off.
$Validator = String::Validator::Email->new(
        allow_ip => 1 , tldcheck => 0 ) ;

#Useful only for author debugging.
# my %switchhash = %{$Validator->{ switchhash }} ;
# my @keys = keys %switchhash ;
# my @values = values %switchhash ;
# note( "Keys    @keys" ) ;
# note( "Values  @values" ) ;

$result = $Validator->Check( 'my.account@[192.168.1.1]' ) ;
is ( $result, 0, 'my.account@[192.168.1.1] passes because allow_ip is on.') ;
is ( $Validator->Errstr , '',
        'bad@email no fqdn should still fail with tldcheck off.' ) ;

$Validator = String::Validator::Email->new(
        allow_ip => 0 ,
        tldcheck => 0 ,
        ) ;

is( $Validator->Check( 'my.account@[142.167.1.1]' ),
        1, 'Allow ip and tld check off, 142.167.1.1 should fail' ) ;
is ( $Validator->Errstr, "fqdn\n", 'Got fqdn Error message for 142.167.1.1');

note( 'Testing with fqdn off - to be meaningful tldcheck also off.' ) ;
$Validator = String::Validator::Email->new(
        allow_ip => 0 ,
        fqdn => 0 ,
		tldcheck => 0 ,
        ) ;

#Useful only for author debugging.
# my %switchhash = %{$Validator->{ switchhash }} ;
# my @keys = keys %switchhash ;
# my @values = values %switchhash ;
# note( "Keys    @keys" ) ;
# note( "Values  @values" ) ;

is( $Validator->Check( 'my.account@[142.167.1.1]' ),
        1, '142.167.1.1 should fail' ) ;
like ( $Validator->Errstr, qr/Looks like it contains an IP Address/,
	'Got IP Error message for 142.167.1.1');
is( $Validator->IsNot_Valid( 'aloitious@algonquin.com' ) ,
    0 , 'aloitious@algonquin.com should be ok.' ) ;
is( $Validator->Is_Valid( 'aloitious@algonquin' ) ,
    1 , 'aloitious@algonquin should be ok because fqdn is off.' ) ;


done_testing() ;


