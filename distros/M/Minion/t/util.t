use Mojo::Base -strict;

use Test::More;
use Minion::Util qw(desired_tasks);

subtest 'desired_tasks' => sub {
  is_deeply desired_tasks({},                   [],                    []),                    [],      'no tasks';
  is_deeply desired_tasks({foo => 2},           ['foo', 'bar'],        ['foo', 'foo']),        ['bar'], 'right tasks';
  is_deeply desired_tasks({foo => 0},           ['foo', 'bar'],        []),                    ['bar'], 'right tasks';
  is_deeply desired_tasks({foo => 2},           ['foo', 'bar'],        ['foo', 'foo', 'foo']), ['bar'], 'right tasks';
  is_deeply desired_tasks({foo => 2, bar => 1}, ['foo', 'bar', 'baz'], ['foo', 'bar', 'foo']), ['baz'], 'right tasks';
  is_deeply desired_tasks({foo => 2, bar => 1}, ['foo', 'bar'],        ['foo', 'foo', 'bar']), [],      'no tasks';
  is_deeply desired_tasks({},                   ['foo', 'bar'],        ['foo', 'foo']), ['foo', 'bar'], 'right tasks';
};

done_testing();
