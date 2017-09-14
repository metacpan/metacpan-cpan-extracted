use Test2::V0 -no_srand => 1;
use Test::Clustericious::Blocking;

note 'force full load of Test2';

is scalar blocking { 'hey there' }, 'hey there', 'scalar context';
is
  [blocking { qw( one two three )}],
  [qw( one two three )],
  'list context';

done_testing;
