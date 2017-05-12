#!/usr/bin/env perl
use strict;
use Test::More tests => 9;
use lib qw(lib);
use Net::Upwork::API::Routers::Activities::Team;

can_ok('Net::Upwork::API::Routers::Activities::Team', 'new');
can_ok('Net::Upwork::API::Routers::Activities::Team', 'get_list');
can_ok('Net::Upwork::API::Routers::Activities::Team', 'get_specific_list');
can_ok('Net::Upwork::API::Routers::Activities::Team', 'add_activity');
can_ok('Net::Upwork::API::Routers::Activities::Team', 'update_activities');
can_ok('Net::Upwork::API::Routers::Activities::Team', 'archive_activities');
can_ok('Net::Upwork::API::Routers::Activities::Team', 'unarchive_activities');
can_ok('Net::Upwork::API::Routers::Activities::Team', 'update_batch');
# local
can_ok('Net::Upwork::API::Routers::Activities::Team', 'get_by_type');
