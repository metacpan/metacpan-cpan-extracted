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
alpha.dc.fabrikam.com. in a 203.0.113.2
SIMPLEZONE

$Net::DNS::DomainController::Discovery::TestResolver = $resolver;

{
	#my $todo = todo 'Not yet implemented';
	my @dc = Net::DNS::DomainController::Discovery->domain_controllers( 'fabrikam.com' );
	is(\@dc, array {
		item [
			'fabrikam.com',
			'alpha.dc.fabrikam.com',
			'203.0.113.2'
		];
		end();
	}, 'One domain controller found');
}
