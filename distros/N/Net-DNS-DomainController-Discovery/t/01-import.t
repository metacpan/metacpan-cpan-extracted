#!perl -T
use Test2::V0;
plan(1);
use Net::DNS::DomainController::Discovery;
not_imported_ok qw/domain_controllers/;
