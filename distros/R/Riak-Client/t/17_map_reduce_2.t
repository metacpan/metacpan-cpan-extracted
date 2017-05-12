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
use Riak::Client;
use JSON::XS;

my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};
my @buckets_to_cleanup = ( qw(training) );

subtest "map reduce with link walking" => sub {
    plan tests => 3;
  
    my $client = Riak::Client->new(
        host => $host,
        port => $port,
    );

    ok( $client->ping(),     "can ping" );
    ok( $client->is_alive(), "should be alive" );      
    
    foreach my $key ( @{ $client->get_keys('training') }){
        diag "deleting training / $key";
        $client->del( training => $key );
    }

    $client->put( training => foo => 'pizza data goes here' ,'text/plain', undef,
                  [ { bucket => 'training',
                      key => 'bar',
                      tag => 'next',
                    } ] );
    $client->put( training => bar => 'pizza pizza pizza pizza' ,'text/plain', undef,
                  [ { bucket => 'training',
                      key => 'baz',
                      tag => 'next',
                    } ]);
    $client->put( training => baz => 'nothing to see here' ,'text/plain', undef,
                  [ { bucket => 'training',
                      key => 'bam',
                      tag => 'next',
                    } ]);
    $client->put( training => bam => 'pizza pizza pizza' ,'text/plain', undef,
                );
    
    my %expected = (
      'training' => 'bar',
    );
    
    
#                  { link => { tag => 'next', keep => Types::Serialiser::true }},

    my $json_hash = {
        inputs => [[ 'training', 'foo' ]],
        query => [
                  {
                   map => {
                           language =>"javascript",
                           source =>"function(riakObject) {
                               var link = riakObject.values[0].metadata.Links[0];
                               return [[ link[0], link[1] ]];
                               
                           }",
                           keep => Types::Serialiser::true,
                          },
                  },
                 ]
    };

#                               var val = riakObject.values[0].data.match(/pizza/g);
#                               return [[riakObject.key, (val ? val.length : 0 )]];
    
    my $json_string = '{
        "inputs":"training",
        "query":[{"map":{"language":"javascript",
        "source":"function(riakObject) {
          var val = riakObject.values[0].data.match(/pizza/g);
          return [[riakObject.bucket, riakObject.key, (val ? val.length : 0 )]];
        }"}}]}';  
        
    foreach my $json_query ( # $json_string, 
                             $json_hash ){
      my $responses = $client->map_reduce($json_query);


      # will return something like
      #[
      #  {'response' => [['foo',1]],'phase' => 0},
      #  {'response' => [['bam',3]],'phase' => 0},
      #  {'response' => [['bar',4]],'phase' => 0},
      #  {'response' => [['baz',0]],'phase' => 0}
      #]

      # it mays also sometimes return
      #[
      #  {'response' => [['foo',1]],'phase' => 0},
      #  {'response' => [['bam',3], ['bar',4]],'phase' => 0},
      #  {'response' => [['baz',0]],'phase' => 0}
      #]
      # now map the key => value

      # now map the key => value

      my %got = map { @$_ } map { @{$_->{response}} } @$responses;

      eq_or_diff \%got , \%expected, "should return the proper data structure for query as: " 
        . ((ref $json_query) ? "reference" : "string") ;      
    }
};
