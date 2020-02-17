#!perl -T
use Test2::V0;
use Net::DNS::Resolver::Mock;
use Net::DNS::RR;
use Data::Dumper;

plan 2;
use Net::DNS::DomainController::Discovery qw(srv_fqdn_list);

my $resolver = Net::DNS::Resolver::Mock->new();

$resolver->zonefile_parse( <<'SIMPLEZONE' );
_ldap._tcp.dc._msdcs.fabrikam.com. 10 in srv 0 100 389 alpha.dc.fabrikam.com.
alpha.dc.fabrikam.com. in a 203.0.113.2
SIMPLEZONE

$Net::DNS::DomainController::Discovery::TestResolver = $resolver;

my @dc = srv_fqdn_list( $resolver, '_ldap._tcp.dc._msdcs.fabrikam.com.' );
Dumper(@dc);

is(\@dc, ['alpha.dc.fabrikam.com']);

$resolver->zonefile_parse( <<'SIMPLEZONE' );
_ldap._udp.dc._msdcs.fabrikam.com. 10 in srv 0 100 389 alpha.dc.fabrikam.com.
alpha.dc.fabrikam.com. in a 203.0.113.2
SIMPLEZONE

$Net::DNS::DomainController::Discovery::TestResolver = $resolver;

like(
	dies {
		srv_fqdn_list( $resolver, '_ldap._tcp.dc._msdcs.fabrikam.com.' );
	}, qr/No SRV record/, "Wanted SRV record should not be found"
)
