#!/usr/bin/env perl
use strict;
use Test::More tests => 2;
use lib qw(lib);
use Net::Upwork::API::Routers::Jobs::Profile;

can_ok('Net::Upwork::API::Routers::Jobs::Profile', 'new');
can_ok('Net::Upwork::API::Routers::Jobs::Profile', 'get_specific');
