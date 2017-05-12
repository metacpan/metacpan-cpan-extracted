#!/usr/bin/env perl
use strict;
use Test::More tests => 7;
use lib qw(lib);
use Net::Upwork::API::Routers::Snapshot;

can_ok('Net::Upwork::API::Routers::Snapshot', 'new');
can_ok('Net::Upwork::API::Routers::Snapshot', 'get');
can_ok('Net::Upwork::API::Routers::Snapshot', 'update');
can_ok('Net::Upwork::API::Routers::Snapshot', 'delete');
can_ok('Net::Upwork::API::Routers::Snapshot', 'get_by_contract');
can_ok('Net::Upwork::API::Routers::Snapshot', 'update_by_contract');
can_ok('Net::Upwork::API::Routers::Snapshot', 'delete_by_contract');
