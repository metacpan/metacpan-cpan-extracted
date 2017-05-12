use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok 'Catalyst::Test', 'Parley' }
BEGIN { use_ok 'Parley::Controller::User' }

ok( request('/user/login')      ->is_success,   'user/login exists'     );
#ok( request('/user/logout')     ->is_success,   'user/logout exists'    );
ok( request('/user/profile')    ->is_success,   'user/profile exists'   );
