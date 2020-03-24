#!perl -T
use Test2::V0;
use Net::DNS::Resolver::Mock;
use Net::DNS::RR;
use Data::Dumper;

plan 1;
use Net::DNS::DomainController::Discovery;

my $resolver = Net::DNS::Resolver::Mock->new();

$resolver->zonefile_parse( <<'SIMPLEZONE' );
_ldap._tcp.dc._msdcs.fabrikam.com. 10 in cname itsme.dc.farbikam.com.
itsme.fabrikam.com. 10 in srv 0 100 389 alpha.dc.fabrikam.com.
itsme.fabrikam.com. 10 in srv 0 100 389 bravo.dc.fabrikam.com.
alpha.dc.fabrikam.com. in a 203.0.113.2
bravo.dc.fabrikam.com. in a 192.0.2.1
SIMPLEZONE

$Net::DNS::DomainController::Discovery::TestResolver = $resolver;

{
	like( dies {
			Net::DNS::DomainController::Discovery::domain_controllers( 'fabrikam.com' );
		}, qr/Need Net::DNS::RR::SRV /,
		"Domain controller SRV record should not point to CNAME"
	);
}
