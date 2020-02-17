#!perl -T
use Test2::V0;

plan 1;

use Net::DNS::DomainController::Discovery qw(domain_controllers);
imported_ok qw/domain_controllers/;
