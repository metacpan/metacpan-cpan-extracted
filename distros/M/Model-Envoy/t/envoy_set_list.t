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

My::Envoy::Models->load_types( qw( Widget ) );

my $set = My::Envoy::Models->m('Widget');

my $params = {
    id    => 1,
    name  => 'foo',
    parts => [],
};

my $model = $set->build($params);

is_deeply( $model->dump, $params );

$model->save();

my @fetch_tests = (
    { result => 'y',   query => [],                 name => 'empty list' },
    { result => 'y',   query => [ id   => 1 ],      name => 'id param' },
    { result => 'y',   query => [ name => 'foo' ],  name => 'name param' },
    { result => 'y',   query => [ id   => 1, name => 'foo' ], name => 'multi param' },
    { result => 'n',   query => [ id   => 2 ],      name => 'missing id' },
    { result => 'n',   query => [ name => 'nope' ], name => 'missing name' },
    { result => 'die', query => [ bad  => 'test' ], name => 'bad query' },
);

for my $test ( @fetch_tests ) {

    subtest $test->{name} => sub {

        if ( $test->{result} eq 'die' ) {
            dies_ok { $set->list( @{$test->{query}} ) } 'bad field spec dies';
        }
        else {

            my $found = $set->list( @{$test->{query}} );

            if ( $test->{result} eq 'y' ) {
                is( scalar( @$found ) , 1, 'just 1 match' );
                isa_ok( $found->[0], 'My::Envoy::Widget');
                is_deeply( $found->[0]->dump, $params );
            }
            elsif ( $test->{result} eq 'n' ) {
                is( scalar( @$found ) , 0, 'just 1 match' );

            }
            else {
                die "cannot interperet desired outcome for test result " . $test->{result};
            }
        };

    }
}

done_testing;