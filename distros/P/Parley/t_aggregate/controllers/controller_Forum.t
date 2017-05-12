use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok 'Catalyst::Test', 'Parley' }
BEGIN { use_ok 'Parley::Controller::Forum' }

ok( request('/forum/list')->is_success, 'forum/list exists' );
ok( request('/forum/view')->is_success, 'forum/view exists' );
