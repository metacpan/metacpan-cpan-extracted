#!/usr/bin/env perl
use strict;
use Test::More tests => 6;
use lib qw(lib);
use Net::Upwork::API::Routers::Reports::Finance::Earnings;

can_ok('Net::Upwork::API::Routers::Reports::Finance::Earnings', 'new');
can_ok('Net::Upwork::API::Routers::Reports::Finance::Earnings', 'get_by_freelancer');
can_ok('Net::Upwork::API::Routers::Reports::Finance::Earnings', 'get_by_freelancers_team');
can_ok('Net::Upwork::API::Routers::Reports::Finance::Earnings', 'get_by_freelancers_company');
can_ok('Net::Upwork::API::Routers::Reports::Finance::Earnings', 'get_by_buyers_team');
can_ok('Net::Upwork::API::Routers::Reports::Finance::Earnings', 'get_by_buyers_company');
