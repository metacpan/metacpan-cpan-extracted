#!/usr/bin/env perl
use strict;
use Test::More tests => 2;
use lib qw(lib);
use Net::Upwork::API::Routers::Jobs::Search;

can_ok('Net::Upwork::API::Routers::Jobs::Search', 'new');
can_ok('Net::Upwork::API::Routers::Jobs::Search', 'find');
