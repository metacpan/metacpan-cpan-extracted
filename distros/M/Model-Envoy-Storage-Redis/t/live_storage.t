use lib 't/lib';

package My::Envoy::Models;

use Moose;
with 'Model::Envoy::Set' => { namespace => 'My::Envoy' };

__PACKAGE__->load_types('CachedWidget');

1;

package main;

BEGIN { $ENV{REDIS_DEBUG} = 1 }

use lib 't/lib';

use Test::More;
use JSON::XS;
 
my $widgets = My::Envoy::Models->m('CachedWidget');

my $test = $widgets->build({
    id   => 1,
    name => 'foo',
});
my $redis = $test->get_storage('Redis')->redis;
my $key = 'id:' . $test->id;

subtest "Saving a Model" => sub {


    ok( ! $test->in_storage('Redis'), 'not in storage');

    my $found = $redis->get($key);
    is( $found, undef, 'redis agrees');

    $test->save();

    ok( $test->in_storage('Redis'), 'in storage now');

    $found = $redis->get($key);
    ok( $found, 'redis agrees');

    is_deeply( decode_json($found), $test->dump, 'data structure matches' );


};

subtest "Fetching a Model" => sub {

    my $test2 = $widgets->fetch(2);

    is( $test2, undef, 'return undef for invalid id');
    is( $redis->get('id:2'), undef, 'redis agrees');

    $test2 = $widgets->fetch(1);

    isa_ok( $test2, 'My::Envoy::CachedWidget', 'successful fetch' );

    is_deeply( $test->dump, $test2->dump, 'found the right record' );
};

subtest "Parameter-based fetch" => sub {

    my $test2 = $widgets->fetch( id => 1);

    isa_ok( $test2, 'My::Envoy::CachedWidget', 'successful fetch' );

    is_deeply( $test->dump, $test2->dump, 'found the right record' );
};

subtest "Deleting a Model" => sub {

    $test->delete;
    ok( ! $test->in_storage('Redis'), 'in_storage agrees');
    is( $redis->get('id:1'), undef, 'redis confirms it is gone');
};


done_testing;
