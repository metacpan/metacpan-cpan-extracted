#!/usr/bin/env perl
use strict;
use Test::More tests => 8;
use lib qw(lib);
use Net::Upwork::API::Routers::Hr::Milestones;

can_ok('Net::Upwork::API::Routers::Hr::Milestones', 'new');
can_ok('Net::Upwork::API::Routers::Hr::Milestones', 'get_active_milestone');
can_ok('Net::Upwork::API::Routers::Hr::Milestones', 'get_submissions');
can_ok('Net::Upwork::API::Routers::Hr::Milestones', 'create');
can_ok('Net::Upwork::API::Routers::Hr::Milestones', 'edit');
can_ok('Net::Upwork::API::Routers::Hr::Milestones', 'activate');
can_ok('Net::Upwork::API::Routers::Hr::Milestones', 'approve');
can_ok('Net::Upwork::API::Routers::Hr::Milestones', 'delete');
