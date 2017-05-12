use Test::More;

BEGIN {
    eval "use Cache::Memcached";
    if ( $@ ) {
        plan skip_all => "Cache::Memcached is required to run this test" ;
    }
}

use FindBin qw/$Bin/;
use lib (
    $Bin."/../../../lib"
);
plan tests => 8;

use_ok('MojoX::Session');
use_ok('MojoX::Session::Store::Memcached');

my $session = MojoX::Session->new(
    store => MojoX::Session::Store::Memcached->new({servers => ['127.0.0.1:11211']})
);

# create
my $sid = $session->create();
ok($sid);
$session->flush();

# load
ok($session->load($sid));
is($session->sid, $sid);

# update
$session->data(foo => 'bar');
$session->flush;
ok($session->load($sid));
is($session->data('foo'), 'bar');

# delete
$session->expire;
$session->flush;
ok(not defined $session->load($sid));
