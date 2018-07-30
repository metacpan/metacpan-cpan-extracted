
use lib 't/lib';

use Test::More;
use My::Envoy::Widget;
use Test::Exception;
use My::Envoy::Part;

my $schema = My::DB->db_connect;
$schema->deploy;

my $test = new My::Envoy::Widget(
    id         => 1,
    name       => 'foo',
    no_storage => 'bar',
    parts    => [ new My::Envoy::Part( id => 2 ) ],
);

subtest "Check dump" => sub {

    is_deeply( $test->dump(), {
        id => 1,
        name => 'foo',
        no_storage => 'bar',
        parts => [ { id => 2 } ],
    });
};

subtest "Updating a Model" => sub {

    note "inspect before update...";

    is( $test->id, 1, "Model id");
    is( $test->name, 'foo', "Model name");
    is( $test->no_storage, 'bar', "Model property without db backing");
    is( ref $test->parts, 'ARRAY', "Model relationship exists");
    is( scalar @{$test->parts}, 1, "Model relationship count" );
    isa_ok( $test->parts->[0], 'My::Envoy::Part', "Related Model" );
    is( $test->parts->[0]->id, 2, "Related Model id" );

    $test->update({
        name => 'new',
        parts => [
            { id => 3, name => 'fizz' },
            { id => 7, name => 'buzz' },
        ]
    });

    is( $test->id, 1, "Model id");
    is( $test->name, 'new');
    is( $test->no_storage, 'bar', "Model property without db backing");
    is( ref $test->parts, 'ARRAY', "Model relationship exists");
    is( scalar @{$test->parts}, 2, "Model relationship count" );
    isa_ok( $test->parts->[0], 'My::Envoy::Part', "Related Model" );
    is( $test->parts->[0]->id, 3, "Related Model id" );
    is( $test->parts->[1]->name, 'buzz', "Related Model name" );

    $test->save;

    ok( $test->in_storage('DBIC') );
    dies_ok( sub { $test->in_storage('NotAThing') } );
};

$test->delete;

done_testing;

1;