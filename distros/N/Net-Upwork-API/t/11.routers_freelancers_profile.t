#!/usr/bin/env perl
use strict;
use Test::More tests => 3;
use lib qw(lib);
use Net::Upwork::API::Routers::Freelancers::Profile;

can_ok('Net::Upwork::API::Routers::Freelancers::Profile', 'new');
can_ok('Net::Upwork::API::Routers::Freelancers::Profile', 'get_specific');
can_ok('Net::Upwork::API::Routers::Freelancers::Profile', 'get_specific_brief');
