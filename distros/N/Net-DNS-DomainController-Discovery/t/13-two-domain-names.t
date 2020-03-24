#!perl -T
use Test2::V0;
use Net::DNS::Resolver::Mock;
use Net::DNS::RR;
use Data::Dumper;

plan 7;
use Net::DNS::DomainController::Discovery;

my $resolver = Net::DNS::Resolver::Mock->new();

$resolver->zonefile_parse( <<'SIMPLEZONE' );
_ldap._tcp.dc._msdcs.fabrikam.com. 10 in srv 0 100 389 alpha.dc.fabrikam.com.
_ldap._tcp.dc._msdcs.contoso.com. 10 in srv 0 100 389 bravo.dc.contoso.com.
alpha.dc.fabrikam.com. in a 203.0.113.2
bravo.dc.contoso.com. in a 192.0.2.1
SIMPLEZONE

$Net::DNS::DomainController::Discovery::TestResolver = $resolver;

{
	my @dc = Net::DNS::DomainController::Discovery::domain_controllers( 'fabrikam.com', 'contoso.com' );
	is(\@dc, array {
		item [
			'fabrikam.com',
			'alpha.dc.fabrikam.com',
			'203.0.113.2'
		];
		item [
			'contoso.com',
			'bravo.dc.contoso.com',
			'192.0.2.1'
		];
		end();
	}, 'One domain controller found one per every of the two domains checked');
}
like( dies {
		Net::DNS::DomainController::Discovery::domain_controllers( 'fabrikam.com', '' );
        }, qr/domain name not defined/, "Empty domain name"
); 
like( dies {
		Net::DNS::DomainController::Discovery::domain_controllers( undef, 'consoso.com' );
        }, qr/domain name not defined/, "Undefined domain name"
); 
like( dies {
		Net::DNS::DomainController::Discovery::domain_controllers( 'local', 'fabrikam.com', 'contoso.com' );
        }, qr/Invalid domain name/, "No top-level domain names"
); 
like( dies {
		Net::DNS::DomainController::Discovery::domain_controllers( 'fabrikam.com', 'łączność.pl' );
        }, qr/Invalid domain name/, "Non-ASCII characters in the  domain name"
); 
like( dies {
		Net::DNS::DomainController::Discovery::domain_controllers( 'fabrikam.com', 'contoso,info' );
        }, qr/Invalid domain name/, "Illegal characters in the domain name"
); 
like( dies {
		Net::DNS::DomainController::Discovery::domain_controllers( 'fabrikam.com', 'x' x 255 . '.pl' );
        }, qr/Invalid domain name/, "Domain name too long"
); 
