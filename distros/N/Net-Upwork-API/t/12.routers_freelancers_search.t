#!/usr/bin/env perl
use strict;
use Test::More tests => 2;
use lib qw(lib);
use Net::Upwork::API::Routers::Freelancers::Search;

can_ok('Net::Upwork::API::Routers::Freelancers::Search', 'new');
can_ok('Net::Upwork::API::Routers::Freelancers::Search', 'find');
