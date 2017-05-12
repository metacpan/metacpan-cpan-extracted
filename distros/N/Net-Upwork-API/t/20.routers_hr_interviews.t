#!/usr/bin/env perl
use strict;
use Test::More tests => 2;
use lib qw(lib);
use Net::Upwork::API::Routers::Hr::Interviews;

can_ok('Net::Upwork::API::Routers::Hr::Interviews', 'new');
can_ok('Net::Upwork::API::Routers::Hr::Interviews', 'invite');
