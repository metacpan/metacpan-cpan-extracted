#!/usr/bin/env perl
use strict;
use Test::More tests => 3;
use lib qw(lib);
use Net::Upwork::API::Routers::Organization::Teams;

can_ok('Net::Upwork::API::Routers::Organization::Teams', 'new');
can_ok('Net::Upwork::API::Routers::Organization::Teams', 'get_list');
can_ok('Net::Upwork::API::Routers::Organization::Teams', 'get_users_in_team');
