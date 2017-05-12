#!/usr/bin/env perl
use strict;
use Test::More tests => 16;
use lib qw(lib);
use Net::Upwork::API;
use Net::Upwork::API::Config;
use Net::Upwork::API::Client;

# API
can_ok('Net::Upwork::API', 'new');
can_ok('Net::Upwork::API', 'init_router');
can_ok('Net::Upwork::API', 'get_access_token');
can_ok('Net::Upwork::API', 'get_authorization_url');
can_ok('Net::Upwork::API', 'has_access_token');
can_ok('Net::Upwork::API', 'client');
# Config
can_ok('Net::Upwork::API::Config', 'new');
# Client
can_ok('Net::Upwork::API::Client', 'new');
can_ok('Net::Upwork::API::Client', 'get_oauth_client');
can_ok('Net::Upwork::API::Client', 'get');
can_ok('Net::Upwork::API::Client', 'post');
can_ok('Net::Upwork::API::Client', 'put');
can_ok('Net::Upwork::API::Client', 'delete');
can_ok('Net::Upwork::API::Client', 'send_request');
can_ok('Net::Upwork::API::Client', 'format_uri');
can_ok('Net::Upwork::API::Client', 'version');
