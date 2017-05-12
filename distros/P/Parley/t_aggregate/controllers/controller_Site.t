use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'Parley' }
BEGIN { use_ok 'Parley::Controller::Site' }

#ok( request('/site')->is_success, 'Request should succeed' );
