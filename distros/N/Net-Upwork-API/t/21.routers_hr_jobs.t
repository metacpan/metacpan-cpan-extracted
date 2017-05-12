#!/usr/bin/env perl
use strict;
use Test::More tests => 6;
use lib qw(lib);
use Net::Upwork::API::Routers::Hr::Jobs;

can_ok('Net::Upwork::API::Routers::Hr::Jobs', 'new');
can_ok('Net::Upwork::API::Routers::Hr::Jobs', 'get_list');
can_ok('Net::Upwork::API::Routers::Hr::Jobs', 'get_specific');
can_ok('Net::Upwork::API::Routers::Hr::Jobs', 'post_job');
can_ok('Net::Upwork::API::Routers::Hr::Jobs', 'edit_job');
can_ok('Net::Upwork::API::Routers::Hr::Jobs', 'delete_job');
