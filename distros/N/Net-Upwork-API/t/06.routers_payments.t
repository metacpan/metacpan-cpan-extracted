#!/usr/bin/env perl
use strict;
use Test::More tests => 2;
use lib qw(lib);
use Net::Upwork::API::Routers::Payments;

can_ok('Net::Upwork::API::Routers::Payments', 'new');
can_ok('Net::Upwork::API::Routers::Payments', 'submit_bonus');
