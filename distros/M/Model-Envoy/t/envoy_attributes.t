
use lib 't/lib';

use Test::More;
use My::Envoy::Widget;
use My::Envoy::Part;

my $test = new My::Envoy::Widget(
    id         => 1,
    name       => 'foo',
    no_storage => 'bar',
    parts    => [ new My::Envoy::Part( id => 2 ) ],
    no_envoy => 'Hi',
);

subtest "check attribute list" => sub {

    is( $test->no_envoy, 'Hi', 'non-envoy attribute is set');
    is_deeply( [ sort map { $_->name } $test->_get_all_attributes ], [ qw( id name no_storage parts ) ], 'non-envoy attribute is skipped' );
};

subtest "Check dump" => sub {

    is_deeply( $test->dump(), {
        id => 1,
        name => 'foo',
        no_storage => 'bar',
        parts => [ { id => 2 } ],
    }, 'non-envoy attribute is not dumped');
};

done_testing;

1;