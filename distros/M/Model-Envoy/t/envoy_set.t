use lib 't/lib';

{
    package My::Envoy::Models;

    use Moose;
    with 'Model::Envoy::Set';

    sub namespace { 'My::Envoy' }

    1;
}

unlink '/tmp/envoy';

use Test::More;
use Test::Exception;
use My::Envoy::Widget;
use My::Envoy::Part;
use My::DB::Result::Widget;
use Data::Dumper; 

My::Envoy::Widget->_schema->storage->dbh->do( My::DB::Result::Widget->sql );
My::Envoy::Widget->_schema->storage->dbh->do( My::DB::Result::Part->sql );

my $set = My::Envoy::Models->m('Widget');

is( $set->model, 'My::Envoy::Widget', 'get set by model name');

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
    { result => 'n',   query => [] },
    { result => 'y',   query => [ 1 ]              },
    { result => 'y',   query => [ id   => 1 ]      },
    { result => 'y',   query => [ name => 'foo' ]  },
    { result => 'y',   query => [ id   => 1, name => 'foo' ] },
    { result => 'n',   query => [ id   => 2 ]      },
    { result => 'n',   query => [ name => 'nope' ] },
    { result => 'die', query => [ bad  => 'test' ] },
);

my $db_params = { %$params };
delete $db_params->{no_storage};

for my $test ( @fetch_tests ) {

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
    }

}

done_testing;