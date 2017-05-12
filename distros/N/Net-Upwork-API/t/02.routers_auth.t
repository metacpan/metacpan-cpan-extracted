#!/usr/bin/env perl
use strict;
use Test::More tests => 2;
use lib qw(lib);
use Net::Upwork::API::Routers::Auth;

can_ok('Net::Upwork::API::Routers::Auth', 'new');
can_ok('Net::Upwork::API::Routers::Auth', 'get_user_info');
