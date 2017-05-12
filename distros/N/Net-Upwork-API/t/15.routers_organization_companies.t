#!/usr/bin/env perl
use strict;
use Test::More tests => 5;
use lib qw(lib);
use Net::Upwork::API::Routers::Organization::Companies;

can_ok('Net::Upwork::API::Routers::Organization::Companies', 'new');
can_ok('Net::Upwork::API::Routers::Organization::Companies', 'get_list');
can_ok('Net::Upwork::API::Routers::Organization::Companies', 'get_specific');
can_ok('Net::Upwork::API::Routers::Organization::Companies', 'get_teams');
can_ok('Net::Upwork::API::Routers::Organization::Companies', 'get_users');
