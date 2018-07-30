
use strict;
use warnings;

use lib 't/lib';

use Test::More;

use My::Envoy::Widget;
use My::Envoy::Part;

my $schema = My::DB->db_connect;
$schema->deploy;

my $test = new My::Envoy::Widget(
    id         => 1,
    name       => 'foo',
    no_storage => 'bar',
    parts    => [ new My::Envoy::Part( id => 2 ) ],
);

my $dbic = $test->get_storage('Model::Envoy::Storage::DBIC');

subtest "Check Metadata" => sub {
    ok( $test->meta->get_attribute('id')->is_primary_key, 'found primary key' );
    ok( $test->meta->get_attribute('parts')->is_relationship, 'found relationship' );
    ok( ! $test->meta->get_attribute('name')->is_relationship, 'found normal property' );
};

subtest "Saving a Model" => sub {

    note "inspect before save...";

    is( $test->id, 1, "Model id");
    is( $test->name, 'foo', "Model name");
    is( $test->no_storage, 'bar', "Model property without db backing");
    is( ref $test->parts, 'ARRAY', "Model relationship exists");
    is( scalar @{$test->parts}, 1, "Model relationship count" );
    isa_ok( $test->parts->[0], 'My::Envoy::Part', "Related Model" );
    is( $test->parts->[0]->id, 2, "Related Model id" );

    isnt( $dbic->_dbic_result->id, 1, "DB id");
    isnt( $dbic->_dbic_result->name, 'foo', "DB name");
    is( scalar $dbic->_dbic_result->parts->all, 0, "DB Relationship" );

    $dbic->save;

    note "inspect after save...";

    is( $test->id, 1);
    is( $test->name, 'foo');
    is( $test->no_storage, 'bar');
    is( ref $test->parts, 'ARRAY');
    is( scalar @{$test->parts}, 1 );
    isa_ok( $test->parts->[0], 'My::Envoy::Part' );
    is( $test->parts->[0]->id, 2 );

    is( $dbic->_dbic_result->id, 1, 'check db id');
    is( $dbic->_dbic_result->name, 'foo', 'check db name');
    is( scalar $dbic->_dbic_result->parts->all, 1, 'Count how many related' );
};

$dbic->delete;

subtest 'Model from DB Result' => sub {

    my $db_test = $schema->resultset('Widget')->new({
        id => 3,
        name => 'baz',
    });
    isa_ok( $db_test, 'My::DB::Result::Widget' );

    my $test2 = My::Envoy::Widget->build($db_test);

    isa_ok( $test2, 'My::Envoy::Widget');
    is( My::Envoy::Widget->build(),undef);
    is( $test2->id, 3 );
    is( $test2->name, 'baz' );

};

done_testing;

1;