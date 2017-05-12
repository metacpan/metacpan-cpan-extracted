#!/usr/bin/env perl
use strict;
use Test::More tests => 4;
use lib qw(lib);
use Net::Upwork::API::Routers::Hr::Submissions;

can_ok('Net::Upwork::API::Routers::Hr::Submissions', 'new');
can_ok('Net::Upwork::API::Routers::Hr::Submissions', 'request_approval');
can_ok('Net::Upwork::API::Routers::Hr::Submissions', 'approve');
can_ok('Net::Upwork::API::Routers::Hr::Submissions', 'reject');
