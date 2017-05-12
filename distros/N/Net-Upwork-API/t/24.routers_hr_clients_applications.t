#!/usr/bin/env perl
use strict;
use Test::More tests => 3;
use lib qw(lib);
use Net::Upwork::API::Routers::Hr::Clients::Applications;

can_ok('Net::Upwork::API::Routers::Hr::Clients::Applications', 'new');
can_ok('Net::Upwork::API::Routers::Hr::Clients::Applications', 'get_list');
can_ok('Net::Upwork::API::Routers::Hr::Clients::Applications', 'get_specific');
