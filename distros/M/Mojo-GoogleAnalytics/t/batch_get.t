use Mojo::Base -strict;
use Mojo::GoogleAnalytics;
use Test::More;

plan skip_all => 'TEST_GA_FILE is not set' unless $ENV{TEST_GA_FILE};
plan skip_all => 'TEST_GA_ID is not set'   unless $ENV{TEST_GA_ID};

my $ga    = Mojo::GoogleAnalytics->new($ENV{TEST_GA_FILE});
my $query = {
  viewId     => $ENV{TEST_GA_ID},
  dateRanges => [{startDate => '7daysAgo', endDate => '1daysAgo'}],
  dimensions => [{name => 'ga:country'}, {name => 'ga:browser'}],
  metrics    => [{expression => 'ga:pageviews'}, {expression => 'ga:sessions'}],
  orderBys   => [{fieldName => 'ga:pageviews', sortOrder => 'DESCENDING'}],
  pageSize   => 10,
};

my $report = $ga->batch_get($query);

ok $report->count > $query->{pageSize}, 'got results';
is $report->error, undef, 'no error';
ok $report->page_token, 'got page_token';
is int(@{$report->rows}), $query->{pageSize}, 'got pageSize rows';
is_deeply $report->query, $query, 'query';
isa_ok($report->tx, 'Mojo::Transaction');

ok $report->maximums->{'ga:pageviews'}, 'maximums ga:pageviews';
ok $report->maximums->{'ga:sessions'},  'maximums ga:sessions';
ok $report->minimums->{'ga:pageviews'}, 'minimums ga:pageviews';
ok $report->minimums->{'ga:sessions'},  'minimums ga:sessions';
ok $report->totals->{'ga:pageviews'},   'totals ga:pageviews';
ok $report->totals->{'ga:sessions'},    'totals ga:sessions';

my $as_hash = $report->rows_to_hash;
my $country = +(keys %$as_hash)[0];

ok $as_hash->{$country}{Chrome}, "$country has Chrome browser";
ok $as_hash->{$country}{Chrome}{'ga:sessions'},  "$country has Chrome browser and ga:sessions stats";
ok $as_hash->{$country}{Chrome}{'ga:pageviews'}, "$country has Chrome browser and ga:pageviews stats";

like $report->rows_to_table(as => 'text'), qr{^ga:country\s+ga:browser\s+ga:pageviews\s+ga:sessions},
  'rows_to_table as text';

my $table = $report->rows_to_table(no_headers => 1);
ok + (grep { $_->[1] =~ /Chrome/ } @$table), 'table has Chrome browser';

done_testing;
