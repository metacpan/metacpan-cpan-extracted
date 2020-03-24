#!perl -T
use Test2::V0;
use Net::DNS::Resolver::Mock;
use Net::DNS::RR;
use Data::Dumper;

plan 1;
use Net::DNS::DomainController::Discovery;

my $resolver = Net::DNS::Resolver::Mock->new();

$resolver->zonefile_parse( <<'SIMPLEZONE' );
_ldap._tcp.dc._msdcs.fabrikam.com. 10 in srv 0 100 389 alpha.dc.fabrikam.com.
_ldap._tcp.dc._msdcs.xn--czno-9saq12bzg.pl. 10 in srv 0 100 389 bravo.dc.xn--czno-9saq12bzg.pl.
alpha.dc.fabrikam.com. in a 203.0.113.2
bravo.dc.xn--czno-9saq12bzg.pl. in a 192.0.2.1
SIMPLEZONE

$Net::DNS::DomainController::Discovery::TestResolver = $resolver;

{
	my @dc = Net::DNS::DomainController::Discovery::domain_controllers( 'fabrikam.com', 'xn--czno-9saq12bzg.pl' );
	is(\@dc, array {
		item [
			'fabrikam.com',
			'alpha.dc.fabrikam.com',
			'203.0.113.2'
		];
		item [
			'xn--czno-9saq12bzg.pl',
			'bravo.dc.xn--czno-9saq12bzg.pl',
			'192.0.2.1'
		];
		end();
	}, 'Punycode-encoded domain names accepted');
}
