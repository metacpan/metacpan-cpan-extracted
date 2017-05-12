use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok 'Catalyst::Test', 'PAR::Repository::Web' }
BEGIN { use_ok 'PAR::Repository::Web::Controller::Repos' }
BEGIN { use_ok 'PAR::Repository::Web::Controller::Root' }

ok( request('/')->is_success, 'Request should succeed' );
ok( request('/repos')->is_success, 'Request should succeed' );


