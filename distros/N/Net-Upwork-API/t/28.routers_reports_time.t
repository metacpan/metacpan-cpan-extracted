#!/usr/bin/env perl
use strict;
use Test::More tests => 8;
use lib qw(lib);
use Net::Upwork::API::Routers::Reports::Time;

can_ok('Net::Upwork::API::Routers::Reports::Time', 'new');
can_ok('Net::Upwork::API::Routers::Reports::Time', 'get_by_team_full');
can_ok('Net::Upwork::API::Routers::Reports::Time', 'get_by_team_limited');
can_ok('Net::Upwork::API::Routers::Reports::Time', 'get_by_agency');
can_ok('Net::Upwork::API::Routers::Reports::Time', 'get_by_company');
can_ok('Net::Upwork::API::Routers::Reports::Time', 'get_by_freelancer_limited');
can_ok('Net::Upwork::API::Routers::Reports::Time', 'get_by_freelancer_full');
# local
can_ok('Net::Upwork::API::Routers::Reports::Time', 'get_by_type');
