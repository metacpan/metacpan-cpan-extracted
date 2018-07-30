
use strict;
use warnings;

use lib 't/lib';

use Test::More;

use My::Envoy::DynamicWidget;

my $schema = My::DB->db_connect;
$schema->deploy;


subtest "Saving with value defined" => sub {

    my $test = new My::Envoy::DynamicWidget(
        id         => 1,
        name       => 'foo',
    );
    my $dbic = $test->get_storage('DBIC');

    note "inspect before save...";

    is( $test->id, 1, "Model id");
    is( $test->name, 'foo', "Model name");

    $test->save;

    note "inspect after save...";

    is( $test->id, 1);
    is( $test->name, 'foo');

    is( $dbic->_dbic_result->id, 1, 'check db id');
    is( $dbic->_dbic_result->name, 'foo', 'check db name');
};

subtest "Saving with value undefined" => sub {

    my $test = new My::Envoy::DynamicWidget(
        id         => 2,
    );
    my $dbic = $test->get_storage('DBIC');

    note "inspect before save...";

    is( $test->id, 2, "Model id");
    is( $test->name, undef, "Model name");

    $dbic->save;

    note "inspect after save...";

    is( $test->id, 2);
    is( $test->name, 'name set');

    is( $dbic->_dbic_result->id, 2, 'check db id');
    is( $dbic->_dbic_result->name, 'name set', 'check db name');
};

done_testing;

1;