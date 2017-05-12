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

subtest "map reduce" => sub {
    plan tests => 6;
  
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

    $client->put( training => foo => 'pizza data goes here' ,'text/plain');
    $client->put( training => bar => 'pizza pizza pizza pizza' ,'text/plain');
    $client->put( training => baz => 'nothing to see here' ,'text/plain');
    $client->put( training => bam => 'pizza pizza pizza' ,'text/plain');
    
    my %expected = (
      'bar' => 4,
      #'baz' => 0,
      'bam' => 3,
      'foo' => 1,
    );
    
    
    my $json_hash = {
        inputs => "training",
        query => [{
          map => {
            language =>"javascript",
            source =>"function(riakObject) {
              var val = riakObject.values[0].data.match(/pizza/g);
              return [[riakObject.key, (val ? val.length : 0 )]];
            }"
          }
        }]
      };
    
    my $json_string = '{
        "inputs":"training",
        "query":[{"map":{"language":"javascript",
        "source":"function(riakObject) {
          var val = riakObject.values[0].data.match(/pizza/g);
          return [[riakObject.key, (val ? val.length : 0 )]];
        }"}}]}';  
        
    foreach my $json_query ( $json_string, $json_hash ){
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

      my $zero = delete $got{baz};
      ok(! $zero, 'should return zero for baz');
      eq_or_diff \%got , \%expected, "should return the proper data structure for query as: " 
        . ((ref $json_query) ? "reference" : "string") ;      
    }
};
