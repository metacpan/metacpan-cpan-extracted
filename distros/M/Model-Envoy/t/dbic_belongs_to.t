
use strict;
use warnings;

use lib 't/lib';

use Test::More;

use My::Envoy::DynamicWidget;
use My::Envoy::DynamicPart;

my $schema = My::DB->db_connect;
$schema->deploy;

my $test = new My::Envoy::DynamicPart(
    id     => 1,
    name   => 'foo',
    widget => new My::Envoy::DynamicWidget(),
);

my $dbic = $test->get_storage('Model::Envoy::Storage::DBIC');

subtest "Saving a Model" => sub {

    $test->save;

    note "inspect after save...";

    is( $test->id, 1);
    is( $test->name, 'foo');
    is( $test->widget->id, '42');
    isa_ok( $test->widget, 'My::Envoy::DynamicWidget' );
};

done_testing;

1;