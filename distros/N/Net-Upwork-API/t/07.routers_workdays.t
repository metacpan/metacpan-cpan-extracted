#!/usr/bin/env perl
use strict;
use Test::More tests => 3;
use lib qw(lib);
use Net::Upwork::API::Routers::Workdays;

can_ok('Net::Upwork::API::Routers::Workdays', 'new');
can_ok('Net::Upwork::API::Routers::Workdays', 'get_by_company');
can_ok('Net::Upwork::API::Routers::Workdays', 'get_by_contract');
