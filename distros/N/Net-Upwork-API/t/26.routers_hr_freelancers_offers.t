#!/usr/bin/env perl
use strict;
use Test::More tests => 3;
use lib qw(lib);
use Net::Upwork::API::Routers::Hr::Freelancers::Applications;

can_ok('Net::Upwork::API::Routers::Hr::Freelancers::Applications', 'new');
can_ok('Net::Upwork::API::Routers::Hr::Freelancers::Applications', 'get_list');
can_ok('Net::Upwork::API::Routers::Hr::Freelancers::Applications', 'get_specific');
