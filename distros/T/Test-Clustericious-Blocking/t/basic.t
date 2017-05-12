use Test2::Bundle::Extended;
use Test::Clustericious::Blocking;

is scalar blocking { 'hey there' }, 'hey there', 'scalar context';
is
  [blocking { qw( one two three )}],
  [qw( one two three )],
  'list context';

done_testing;
