use Test::More;

BEGIN {
    eval "use MongoDB";
    if ($@) {
        plan skip_all => "MongoDB.pm installed is required to run this test";
    }

    eval "MongoDB::Connection->new(host => 'localhost');";
    if ($@) {
        plan skip_all => "MongoDB on localhost is required to run this test";
    }

}

use FindBin qw/$Bin/;
use lib ($Bin . "/../../../lib");
plan tests => 15;

use_ok('MojoX::Session');
use_ok('MojoX::Session::Store::MongoDB');

ok(my $session = MojoX::Session->new(
    store => MojoX::Session::Store::MongoDB->new(
        {   host       => '127.0.0.1',
            collection => 'sessions',
            database   => 'test',
        }
    )
), "new session object");

# create
ok(my $sid = $session->create(), 'create session');
ok($sid,              'got session id');
ok($session->flush(), 'flush');

# load
ok($session->load($sid), 'load session id');
is($session->sid, $sid, 'got sid back');

# update
ok($session->data(foo => 'bar'), 'setting data');
ok($session->flush,      'flushing');
ok($session->load($sid), 'loading again');
is($session->data('foo'), 'bar', 'foo is set right');

# delete
ok($session->expire, 'expire');

# the API is weird -- when expired flush just uses return;
$session->flush;

ok($session = MojoX::Session->new(
    store => MojoX::Session::Store::MongoDB->new(
        {   
          mongodb => MongoDB::Connection->new(host => 'localhost')->get_database("test"),
          collection => 'sessions',
        }
    )
), "new session with MongoDB object");


is($session->load($sid), undef, "get undef loading expired session");


