#!/usr/bin/env perl
use strict;
use Test::More tests => 3;
use lib qw(lib);
use Net::Upwork::API::Routers::Graphql;

can_ok('Net::Upwork::API::Routers::Graphql', 'new');
can_ok('Net::Upwork::API::Routers::Graphql', 'set_org_uid_header');
can_ok('Net::Upwork::API::Routers::Graphql', 'execute');
