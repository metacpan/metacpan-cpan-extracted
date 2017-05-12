#!/usr/bin/env perl
use strict;
use Test::More tests => 4;
use lib qw(lib);
use Net::Upwork::API::Routers::Hr::Contracts;

can_ok('Net::Upwork::API::Routers::Hr::Contracts', 'new');
can_ok('Net::Upwork::API::Routers::Hr::Contracts', 'suspend_contract');
can_ok('Net::Upwork::API::Routers::Hr::Contracts', 'restart_contract');
can_ok('Net::Upwork::API::Routers::Hr::Contracts', 'end_contract');
