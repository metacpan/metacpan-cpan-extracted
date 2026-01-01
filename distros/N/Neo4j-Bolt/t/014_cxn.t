use v5.12;
use warnings;
use Test2::V0 -target => 'Neo4j::Bolt::Cxn';

my $cxn = CLASS->new_();
is $cxn->connected, 0, 'connected 0';
is $cxn->errnum, 0, 'errnum 0';

{
  local $Neo4j::Bolt::DEFAULT_DB = 'neo4j';
  my $mock = mock $cxn, override => [
    connected  => 1,
    run_query_ => sub { shift; \@_ },
  ];
  
  for my $is_send_query (0 .. 1) {
    my $run_query = $is_send_query ? 'send_query' : 'run_query';

    ok dies { $cxn->$run_query('') },
      "$run_query: empty query";
    is $cxn->$run_query('MATCH (a) RETURN a'),
      ['MATCH (a) RETURN a', {}, $is_send_query, 'neo4j'],
      "$run_query: no params";

    ok dies { $cxn->$run_query('MATCH (n) RETURN n', key => 'value') },
      "$run_query: params not a ref";
    ok dies { $cxn->$run_query('MATCH (n) RETURN n', [key => 'value']) },
      "$run_query: params not a hash ref";
    is $cxn->$run_query('MATCH (b) RETURN b', {key => 'value'}),
      ['MATCH (b) RETURN b', {key => 'value'}, $is_send_query, 'neo4j'],
      "$run_query: params hash ref given";

    is $cxn->$run_query('MATCH (c) RETURN c', {}, 'foo'),
      ['MATCH (c) RETURN c', {}, $is_send_query, 'foo'],
      "$run_query: custom db";
  }
}

done_testing;
