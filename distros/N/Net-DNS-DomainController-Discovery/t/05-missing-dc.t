#!perl -T
use Test2::V0;
use Net::DNS::Resolver::Mock;
use Net::DNS::RR;
use Data::Dumper;

plan 1;
use Net::DNS::DomainController::Discovery;

like( dies {
		Net::DNS::DomainController::Discovery::domain_controllers();
	}, qr/Active Directory domain name not provided/, "Need at least one domain name"
);
