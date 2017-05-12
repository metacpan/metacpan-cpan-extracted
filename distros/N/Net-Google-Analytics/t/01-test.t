#!perl -w
use strict;

use Test::More tests => 47;

our $expect_url;
our $content;

sub get {
    my ($self, $url, %params) = @_;

    is($url, $expect_url, 'url');
    is_deeply(
        \%params,
        {
            'Auth-Test' => 'auth_value 123',
        },
        'auth_params',
    );

    return $self;
}

sub is_success      { return 1; }
sub code            { return 200; }
sub message         { return 'Success'; }
sub decoded_content { return $content; }

use_ok("Net::Google::Analytics");

my $analytics = Net::Google::Analytics->new();
ok($analytics, 'new');

my $ua = $analytics->user_agent;
ok($ua, 'get user_agent');

$analytics->user_agent(__PACKAGE__);

$analytics->auth_params('Auth-Test' => 'auth_value 123');

my ($req, $res, $rows);

$req = $analytics->new_request();
$req->ids('ga:1234567');
$req->dimensions('ga:country');
$req->metrics('ga:visits');
$req->sort('-ga:visits');
$req->start_index(1);
$req->max_results(20);
$req->start_date('2010-01-01');
$req->end_date('2010-01-31');
$req->sampling_level('HIGHER_PRECISION');

$expect_url = 'https://www.googleapis.com/analytics/v3/data/ga?ids=ga%3A1234567&start-date=2010-01-01&end-date=2010-01-31&metrics=ga%3Avisits&dimensions=ga%3Acountry&sort=-ga%3Avisits&samplingLevel=HIGHER_PRECISION&start-index=1&max-results=20';
$content = <<'EOF';
{
 "kind": "analytics#gaData",
 "id": "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:1234567&dimensions=ga:medium,ga:source&metrics=ga:bounces,ga:newVisits&sort=-ga:newVisits&filters=ga:medium%3D%3Dreferral&start-date=2008-10-01&end-date=2008-10-31&start-index=1&max-results=5",
 "query": {
  "start-date": "2008-10-01",
  "end-date": "2008-10-31",
  "ids": "ga:1234567",
  "dimensions": "ga:medium,ga:source",
  "metrics": [
   "ga:bounces",
   "ga:newVisits"
  ],
  "sort": [
   "-ga:newVisits"
  ],
  "filters": "ga:medium==referral",
  "start-index": 1,
  "max-results": 5
 },
 "itemsPerPage": 5,
 "totalResults": 6451,
 "selfLink": "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:1234567&dimensions=ga:medium,ga:source&metrics=ga:bounces,ga:newVisits&sort=-ga:newVisits&filters=ga:medium%3D%3Dreferral&start-date=2008-10-01&end-date=2008-10-31&start-index=1&max-results=5",
 "nextLink": "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:1234567&dimensions=ga:medium,ga:source&metrics=ga:bounces,ga:newVisits&sort=-ga:newVisits&filters=ga:medium%3D%3Dreferral&start-date=2008-10-01&end-date=2008-10-31&start-index=6&max-results=5",
 "profileInfo": {
  "profileId": "1234567",
  "accountId": "7654321",
  "webPropertyId": "UA-7654321-1",
  "internalWebPropertyId": "9999999",
  "profileName": "Test Profile",
  "tableId": "ga:1234567"
 },
 "containsSampledData": false,
 "columnHeaders": [
  {
   "name": "ga:MEDium",
   "columnType": "DIMENSION",
   "dataType": "STRING"
  },
  {
   "name": "ga:source",
   "columnType": "DIMENSION",
   "dataType": "STRING"
  },
  {
   "name": "ga:bounces",
   "columnType": "METRIC",
   "dataType": "INTEGER"
  },
  {
   "name": "ga:newVISits",
   "columnType": "METRIC",
   "dataType": "INTEGER"
  }
 ],
 "totalsForAllResults": {
  "ga:bounces": "101535",
  "ga:newVisits": "136540"
 },
 "rows": [
  [
   "referral",
   "blogger.com",
   "61095",
   "68140"
  ],
  [
   "referral",
   "google.com",
   "14979",
   "29666"
  ],
  [
   "referral",
   "stumbleupon.com",
   "848",
   "4012"
  ],
  [
   "referral",
   "google.co.uk",
   "2084",
   "2968"
  ],
  [
   "referral",
   "google.co.in",
   "1891",
   "2793"
  ]
 ]
}
EOF

$res = $analytics->retrieve($req);
ok($res, 'retrieve data');
ok($res->is_success, 'retrieve success');

is($res->num_rows, 5, 'num_rows');
is($res->total_results, 6451, 'total_results');
is($res->start_index, 1, 'start_index');
is($res->items_per_page, 5, 'items_per_page');
ok(!$res->contains_sampled_data, 'contains_sampled_data');
is($res->profile_info->{profileName}, 'Test Profile', 'profile_info');

my $column_headers = $res->_column_headers;
ok($column_headers, 'column headers');
is($column_headers->[0]->{name}, 'medium');
is($column_headers->[2]->{column_type}, 'METRIC');
is($column_headers->[3]->{data_type}, 'INTEGER');

my @metrics = $res->metrics;
is_deeply(\@metrics, [ qw(bounces new_visits) ]);

my @dimensions = $res->dimensions;
is_deeply(\@dimensions, [ qw(medium source) ]);

$rows = $res->rows;
ok($rows, 'rows');
is(@$rows, 5, 'count rows');

is($rows->[0]->get_medium, 'referral');
is($rows->[1]->get_source, 'google.com');
is($rows->[2]->get_new_visits, '4012');
is($rows->[4]->get_bounces, '1891');
is($rows->[3]->get('new_visits'), '2968');

is($res->totals('bounces'), '101535');
is($res->totals('new_visits'), '136540');

# Test class cache

my $class = ref($rows->[0]);
$res = $analytics->retrieve($req);
is(ref($res->rows->[0]), $class, 'class cache works');

# Test projection

my $projection = $res->project([ 'domain_style' ], sub {
    my $row = shift;

    return $row->get_source =~ /\.co\.[a-z]+\z/i ?
        'dot-co-domain' :
        'other';
});

ok($projection, 'projection');
ok($projection->is_success, 'is_success of projection');
is($projection->num_rows, 2, 'num_rows of projection');
is($projection->total_results, 2, 'total_results of projection');
is($projection->start_index, 1, 'start_index of projection');
is($projection->items_per_page, 2, 'items_per_page of projection');

@metrics = $projection->metrics;
is_deeply(\@metrics, [ qw(bounces new_visits) ], 'metrics of projection');

@dimensions = $projection->dimensions;
is_deeply(\@dimensions, [ qw(domain_style) ], 'dimensions of projection');

$rows = $projection->rows;
ok($rows, 'rows of projection');
is(@$rows, 2, 'count rows of projection');

for my $row (@$rows) {
    if ($row->get_domain_style eq 'dot-co-domain') {
        is($row->get_new_visits, 5_761);
        is($row->get_bounces, 3_975);
    }
    else {
        is($row->get_new_visits, 101_818);
        is($row->get_bounces,  76_922);
    }
}

is($projection->totals('bounces'), '101535', 'total bounces of proj');
is($projection->totals('new_visits'), '136540', 'total new_visits of proj');

