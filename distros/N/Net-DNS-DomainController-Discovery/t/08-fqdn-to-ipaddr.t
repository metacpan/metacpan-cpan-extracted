#!perl -T
use Test2::V0;
use Net::DNS::Resolver::Mock;
use Net::DNS::RR;
use Data::Dumper;

plan 5;
use Net::DNS::DomainController::Discovery qw(fqdn_to_ipaddr);

like( dies {
		fqdn_to_ipaddr();
	}, qr/Need Net::DNS::RR record/, "Got exception"
);
like( dies {
		fqdn_to_ipaddr(new Net::DNS::RR('test. cname dupa.'));
	}, qr/Need Net::DNS::RR::A /, "CNAME is not A"
);
like( dies {
		fqdn_to_ipaddr(new Net::DNS::RR('test in srv 10 100 389 dupa.fabrikam.com.'));
	}, qr/Need Net::DNS::RR::A /, "SRV is not A"
);
is(fqdn_to_ipaddr(new Net::DNS::RR('test in a 127.0.0.1')), '127.0.0.1');
is(fqdn_to_ipaddr(new Net::DNS::RR('test in aaaa ::1')), '0:0:0:0:0:0:0:1');
