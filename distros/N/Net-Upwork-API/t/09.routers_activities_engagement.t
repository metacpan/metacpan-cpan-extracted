#!/usr/bin/env perl
use strict;
use Test::More tests => 4;
use lib qw(lib);
use Net::Upwork::API::Routers::Activities::Engagement;

can_ok('Net::Upwork::API::Routers::Activities::Engagement', 'new');
can_ok('Net::Upwork::API::Routers::Activities::Engagement', 'get_specific');
can_ok('Net::Upwork::API::Routers::Activities::Engagement', 'assign');
can_ok('Net::Upwork::API::Routers::Activities::Engagement', 'assign_to_engagement');
