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

My::Envoy::Models->load_types( qw( Widget Part ) );

my $set = My::Envoy::Models->m('Widget');

is( $set->model_class, 'My::Envoy::Widget', 'get set by model name');

my $params = {
    id => 1,
    name => 'foo',
    no_storage => 'bar',
    parts => [
        {
            id => 2,
            name => 'baz',
        },
    ],
};

my $model = $set->build($params);

is_deeply( $model->dump, $params );

$model->save();

my @fetch_tests = (
    { result => 'n',   query => [],                 name => 'empty fetch' },
    { result => 'y',   query => [ 1 ],              name => 'raw id' },
    { result => 'y',   query => [ id   => 1 ],      name => 'id param' },
    { result => 'y',   query => [ name => 'foo' ],  name => 'name param' },
    { result => 'y',   query => [ id   => 1, name => 'foo' ], name => 'multi param' },
    { result => 'n',   query => [ id   => 2 ],      name => 'missing id' },
    { result => 'n',   query => [ name => 'nope' ], name => 'missing name' },
    { result => 'die', query => [ bad  => 'test' ], name => 'bad query' },
);

my $db_params = { %$params };
delete $db_params->{no_storage};

for my $test ( @fetch_tests ) {

    subtest $test->{name} => sub {

        if ( $test->{result} eq 'die' ) {
            dies_ok { $set->fetch( @{$test->{query}} ) } 'bad field spec dies';
        }
        else {

            my @found = $set->fetch( @{$test->{query}} );

            if ( $test->{result} eq 'y' ) {
                is( scalar( @found ) , 1, 'just 1 match' );
                isa_ok( $found[0], 'My::Envoy::Widget');
                is_deeply( $found[0]->dump, $db_params );
            }
            elsif ( $test->{result} eq 'n' ) {
                is( scalar( @found ) , 1, 'just 1 match' );
                ok( ! defined $found[0] , 'no match found for '. Dumper $test->{query} );

            }
            else {
                die "cannot interperet desired outcome for test result " . $test->{result};
            }
        };

    }
}

done_testing;