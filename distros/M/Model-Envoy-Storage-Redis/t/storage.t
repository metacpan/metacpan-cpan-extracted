use lib 't/lib';

package My::Envoy::Models;

use Moose;
with 'Model::Envoy::Set' => { namespace => 'My::Envoy' };

__PACKAGE__->load_types('Widget');

1;

package main;

use lib 't/lib';

use Test::More 'no_plan';
use My::Envoy::Widget;
use MockRedis;

my $widgets = My::Envoy::Models->m('Widget');

my $test = $widgets->build({
    id   => 1,
    name => 'foo',
});
my $key = 'id:' . $test->id;

subtest "Saving a Model" => sub {


    ok( ! exists $MockRedis::storage{$key}, 'not yet stored' );
    ok( ! $test->in_storage('Redis'), 'in_storage agrees');

    $test->save();

    ok( exists $MockRedis::storage{$key}, 'now stored' );
    ok( $test->in_storage('Redis'), 'in_storage agrees');


};

subtest "listing Models" => sub {

    my $test2 = $widgets->list( id => 1 );

    is( $test2, undef, 'unimplemented' );
};

subtest "Fetching a Model" => sub {

    my $test2 = $widgets->fetch(2);

    is( $test2, undef, 'return undef for invalid id');

    $test2 = $widgets->fetch(1);

    isa_ok( $test2, 'My::Envoy::Widget', 'successful fetch' );

    is_deeply( $test->dump, $test2->dump, 'found the right record' );
};

subtest "Parameter-based fetch" => sub {

    my $test2 = $widgets->fetch( id => 1);

    isa_ok( $test2, 'My::Envoy::Widget', 'successful fetch' );

    is_deeply( $test->dump, $test2->dump, 'found the right record' );
};

subtest "Deleting a Model" => sub {

    $test->delete;
    ok( ! exists $MockRedis::storage{$key}, 'not in storage anymore' );
    ok( ! $test->in_storage('Redis'), 'in_storage agrees');
};

done_testing;
