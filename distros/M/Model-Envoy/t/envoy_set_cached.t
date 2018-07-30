use lib 't/lib';

package My::Envoy::Models;

use Moose;
with 'Model::Envoy::Set' => { namespace => 'My::Envoy' };

1;

package main;

use Test::More;
use Test::Exception;
use My::DB::Result::Widget;
use Data::Dumper;
use My::DB;

my $schema = My::DB->db_connect;
$schema->deploy;

My::Envoy::Models->load_types( qw( CachedWidget ) );

my $set = My::Envoy::Models->m('CachedWidget');

my $params = {
    id   => 1,
    name => 'foo',
};

my $model = $set->build($params);

ok( ! $model->in_storage('DBIC'), 'not in db');
ok( ! $model->in_cache('Memory'), 'not in cache' );
ok( ! $model->in_storage('Memory'), 'not using this plugin for storage' );

$model->save();

ok( $model->in_storage('DBIC'), 'in db');
ok( $model->in_cache('Memory'), 'in cache' );
ok( $model->in_storage('Memory'), 'still not using this plugin for storage' );


subtest 'simple cached fetch' => sub {

    note "fetching model";
    my $found = $set->fetch( 1 );

    isa_ok( $found, 'My::Envoy::CachedWidget', 'found it' );
    ok( ! $found->in_storage('DBIC'), 'not backed by db yet');
    ok( $found->in_cache('Memory'), 'still in cache');

    is_deeply( $found->dump, $model->dump, 'fetched copy matches original' );
};

subtest 'cache miss' => sub {

    note "manually delete from cache";
    $model->get_cache('Memory')->delete;

    ok( $model->in_storage('DBIC'), 'still in db');
    ok( ! $model->in_cache('Memory'), 'not in cache');

    note "fetching model";
    my $found = $set->fetch( 1 );

    isa_ok( $found, 'My::Envoy::CachedWidget', 'found it' );
    ok( $found->in_storage('DBIC'), 'still in db');
    ok( $found->in_cache('Memory'), 'in cache again');
    is_deeply( $found->dump, $model->dump, 'fetched copy matches original' );
};

subtest 'cache hit' => sub {
    note "fetching model";
    my $found = $set->fetch( 1 );

    isa_ok( $found, 'My::Envoy::CachedWidget' );
    ok( ! $found->in_storage('DBIC'), 'not backed by db yet');
    ok( $found->in_cache('Memory'), 'in cache again');
    is_deeply( $found->dump, $model->dump, 'fetched copy matches original' );

    note "updating model";
    $found->update({ name => 'bar' })->save();

    ok( $found->in_storage('DBIC'), 'now backed by db');
    ok( $found->in_cache('Memory'), 'still in cache');

    note "fetching model again";
    my $found2 = $set->fetch(1);

    ok( ! $found2->in_storage('DBIC'), 'not backed by db yet');
    ok( $found2->in_cache('Memory'), 'in cache though');
    is_deeply( $found->dump, $found2->dump, 'two fetched copies match' );
};

subtest 'gone' => sub {

    note "delete model everywhere";
    $model->delete();
    ok( ! $model->in_storage('DBIC'), 'deleted from db'   );
    ok( ! $model->in_cache('Memory'), 'deleted from cache');

    note "fetch to make sure";
    my $found = $set->fetch( 1 );

    is( $found, undef, 'it is gone' );
};

done_testing;