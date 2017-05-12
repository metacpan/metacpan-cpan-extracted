use strict;
use warnings;
use Test::More tests => 9;

BEGIN { use_ok 'Catalyst::Test', 'Parley' }
BEGIN { use_ok 'Parley::Controller::Thread' }

ok( request('/thread/add')      ->is_success,   'thread/add exists'         );
ok( request('/thread/next_post')->is_success,   'thread/next_post exists'   );
ok( request('/thread/recent')   ->is_success,   'thread/recent exists'      );
ok( request('/thread/reply')    ->is_success,   'thread/reply exists'       );
ok( request('/thread/view')     ->is_success,   'thread/view exists'        );
ok( request('/thread/watch')    ->is_success,   'thread/watch exists'       );
ok( request('/thread/watches')  ->is_success,   'thread/watches exists'     );
