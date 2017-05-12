#!/usr/bin/env perl
use strict;
use Test::More tests => 4;
use lib qw(lib);
use Net::Upwork::API::Routers::Hr::Clients::Offers;

can_ok('Net::Upwork::API::Routers::Hr::Clients::Offers', 'new');
can_ok('Net::Upwork::API::Routers::Hr::Clients::Offers', 'get_list');
can_ok('Net::Upwork::API::Routers::Hr::Clients::Offers', 'get_specific');
can_ok('Net::Upwork::API::Routers::Hr::Clients::Offers', 'make_offer');
