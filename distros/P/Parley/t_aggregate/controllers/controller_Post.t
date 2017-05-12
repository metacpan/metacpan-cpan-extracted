use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok 'Catalyst::Test', 'Parley' }
BEGIN { use_ok 'Parley::Controller::Post' }

ok( request('/post/edit')->is_success, 'post/edit exists' );
ok( request('/post/view')->is_success, 'post/view exists' );
ok( request('/post/preview')->is_success, 'post/preview exists' );
