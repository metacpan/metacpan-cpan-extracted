#!/usr/bin/env perl
use strict;
use Test::More tests => 3;
use lib qw(lib);
use Net::Upwork::API::Routers::Hr::Engagements;

can_ok('Net::Upwork::API::Routers::Hr::Engagements', 'new');
can_ok('Net::Upwork::API::Routers::Hr::Engagements', 'get_list');
can_ok('Net::Upwork::API::Routers::Hr::Engagements', 'get_specific');
