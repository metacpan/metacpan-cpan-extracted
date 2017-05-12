use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok 'Catalyst::Test', 'Parley' }
BEGIN { use_ok 'Parley::Controller::Terms' }

ok( request('/terms')->is_success, 'Terms are viewable' );
ok( request('/terms/accept')->is_success, 'terms/accept exists' );
ok( request('/terms/add')->is_success, 'terms/add exists' );
