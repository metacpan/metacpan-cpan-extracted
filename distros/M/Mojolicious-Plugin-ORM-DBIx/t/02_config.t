use v5.26;
use warnings;

use Test2::V0;
use Mojolicious::Lite;

push(@INC, "t/classes");
app->moniker('MyApp');

ok(plugin('ORM::DBIx'), 'load module as plugin');
ok(app->db,             'get schema');
ok(app->model("User"),  'get user resultset');

done_testing;
