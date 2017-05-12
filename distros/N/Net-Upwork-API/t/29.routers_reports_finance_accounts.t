#!/usr/bin/env perl
use strict;
use Test::More tests => 3;
use lib qw(lib);
use Net::Upwork::API::Routers::Reports::Finance::Accounts;

can_ok('Net::Upwork::API::Routers::Reports::Finance::Accounts', 'new');
can_ok('Net::Upwork::API::Routers::Reports::Finance::Accounts', 'get_owned');
can_ok('Net::Upwork::API::Routers::Reports::Finance::Accounts', 'get_specific');
