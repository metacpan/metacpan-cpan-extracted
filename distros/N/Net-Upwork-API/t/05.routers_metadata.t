#!/usr/bin/env perl
use strict;
use Test::More tests => 6;
use lib qw(lib);
use Net::Upwork::API::Routers::Metadata;

can_ok('Net::Upwork::API::Routers::Metadata', 'new');
can_ok('Net::Upwork::API::Routers::Metadata', 'get_categories_v2');
can_ok('Net::Upwork::API::Routers::Metadata', 'get_skills');
can_ok('Net::Upwork::API::Routers::Metadata', 'get_regions');
can_ok('Net::Upwork::API::Routers::Metadata', 'get_tests');
can_ok('Net::Upwork::API::Routers::Metadata', 'get_reasons');
