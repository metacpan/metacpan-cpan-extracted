#!/usr/bin/env perl
use strict;
use Test::More tests => 3;
use lib qw(lib);
use Net::Upwork::API::Routers::Organization::Users;

can_ok('Net::Upwork::API::Routers::Organization::Users', 'new');
can_ok('Net::Upwork::API::Routers::Organization::Users', 'get_my_info');
can_ok('Net::Upwork::API::Routers::Organization::Users', 'get_specific');
