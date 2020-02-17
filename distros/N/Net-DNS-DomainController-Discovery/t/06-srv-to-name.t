#!perl -T
use Test2::V0;
use Net::DNS::Resolver::Mock;
use Net::DNS::RR;
use Data::Dumper;

plan 3;
use Net::DNS::DomainController::Discovery qw(srv_to_name);

like( dies {
		srv_to_name();
	}, qr/Need Net::DNS::RR record/, "Got exception"
);
like( dies {
		srv_to_name(new Net::DNS::RR('test. a 127.0.0.1'));
	}, qr/Need Net::DNS::RR::SRV record/, "Got exception"
);
is(srv_to_name(new Net::DNS::RR('test in srv 10 100 389 dupa.fabrikam.com.')),
	'dupa.fabrikam.com', "Extracted name matches");
