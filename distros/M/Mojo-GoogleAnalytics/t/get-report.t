use Mojo::Base -strict;
use Mojo::GoogleAnalytics;
use Mojo::JSON qw(false true);
use Test::More;

plan skip_all => 'reason' if 0;

my $ga = Mojo::GoogleAnalytics->new(view_id => '123');

is_deeply(
  $ga->_query_translator(
    filters => [
      ['x'         => 'eq'     => ['foo']],
      ['y'         => '^'      => ['whatever']],
      ['ga:lt'     => '<'      => '2'],
      ['z'         => '!$'     => ['whatever']],
      ['ga:match'  => '=~'     => ['X']],
      ['ga:substr' => 'substr' => ['bar']],
      ['ga:gt'     => '>'      => '0'],
      ['ga:eq'     => '=='     => '10'],
    ]
  ),
  {
    viewId                 => '123',
    dimensionFilterClauses => [
      {
        filters => [
          {dimensionName => 'x',         operator => 'EXACT',       not => false, expressions => ['foo']},
          {dimensionName => 'y',         operator => 'BEGINS_WITH', not => false, expressions => ['whatever']},
          {dimensionName => 'z',         operator => 'ENDS_WITH',   not => true,  expressions => ['whatever']},
          {dimensionName => 'ga:match',  operator => 'REGEXP',      not => false, expressions => ['X']},
          {dimensionName => 'ga:substr', operator => 'PARTIAL',     not => false, expressions => ['bar']},
        ]
      }
    ],
    metricFilterClauses => [
      {
        filters => [
          {metricName => 'ga:lt', operator => 'LESS_THAN',    not => false, comparisonValue => '2'},
          {metricName => 'ga:gt', operator => 'GREATER_THAN', not => false, comparisonValue => '0'},
          {metricName => 'ga:eq', operator => 'EQUAL',        not => false, comparisonValue => '10'},
        ]
      }
    ],
  },
  'filters'
);

is_deeply($ga->_query_translator(interval => ['7daysAgo']),
  {viewId => '123', dateRanges => [{startDate => '7daysAgo', endDate => '1daysAgo'}]}, 'order_by');

is_deeply($ga->_query_translator(interval => [qw(x y)], rows => 30),
  {viewId => '123', dateRanges => [{startDate => 'x', endDate => 'y'}], pageSize => 30}, 'order_by');

is_deeply($ga->_query_translator(dimensions => 'x,y,z'),
  {viewId => '123', dimensions => [{name => 'x'}, {name => 'y'}, {name => 'z'}]}, 'dimensions');

is_deeply($ga->_query_translator(metrics => 'x,y,z'),
  {viewId => '123', metrics => [{expression => 'x'}, {expression => 'y'}, {expression => 'z'}]}, 'metrics');

is_deeply(
  $ga->_query_translator(order_by => ['foo asc', 'bar', 'baz desc']),
  {
    viewId   => '123',
    orderBys => [
      {fieldName => 'foo', sortOrder => 'ASCENDING'},
      {fieldName => 'bar', sortOrder => 'SORT_ORDER_UNSPECIFIED'},
      {fieldName => 'baz', sortOrder => 'DESCENDING'},
    ]
  },
  'order_by'
);

done_testing;
