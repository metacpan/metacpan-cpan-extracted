BEGIN {
    unless ( $ENV{RIAK_PBC_HOST} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'variable RIAK_PBC_HOST is not defined' );
    }
}

use Test::More tests => 1;
use Test::Differences;
use Test::Exception;
use Riak::Light;
use JSON;

subtest "map reduce" => sub {
    plan tests => 2;

    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Light->new(
        host             => $host, port => $port,
        timeout_provider => undef
    );

    ok( $client->ping(), "should can ping" );

    my $keys = $client->get_keys('training');

    foreach my $key ( @{$keys} ) {
        $client->del( training => $key );
    }

    $client->put( training => foo => '...', 'text/plain',
        { last_modify_int => 1, tag_bin => [ 'even', 'odd' ] } );
    $client->put( training => bar => '...', 'text/plain',
        { last_modify_int => 2 } );
    $client->put( training => baz => '...', 'text/plain',
        { last_modify_int => 3, tag_bin => ['even'] } );
    $client->put( training => bam => '...', 'text/plain',
        { last_modify_int => 4, tag_bin => ['odd'] } );

    my $json_hash = {
        inputs => {
            bucket => 'training',
            index  => 'last_modify_int',
            start  => 2,
            end    => 3,
        },
        query => [
            {   map => {
                    language => "javascript",
                    source   => "function(riakObject) {
              var indexes = riakObject.values[0].metadata.index;
              var tag_bin = indexes.tag_bin;
              
              return (tag_bin)? [
                [
                  riakObject.key, tag_bin
                ]
              ] : [];
            }"
                }
            }
        ]
    };

    my $data = [];
    $client->map_reduce(
        $json_hash,
        sub {
            ( $data, undef ) = @_;
        }
    );

    eq_or_diff $data, [ [ 'baz', 'even' ] ],
      'should return the map_reduce result';
};
