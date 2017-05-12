#!perl -w
use strict;

use Test::More qw/no_plan/;

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

$req = $analytics->new_request(realtime => 1);
$req->ids('ga:1234567');
$req->dimensions('ga:pagePath');
$req->metrics('ga:activeVisitors');
$req->sort('-ga:activeVisitors');
$req->max_results(5);

$expect_url = 'https://www.googleapis.com/analytics/v3/data/realtime?ids=ga%3A1234567&metrics=ga%3AactiveVisitors&dimensions=ga%3ApagePath&sort=-ga%3AactiveVisitors&max-results=5';
$content = <<'EOF';
{
    "totalsForAllResults" : {
        "ga:activeVisitors" : "111022"
    },
    "query" : {
        "sort" : [
            "-ga:activeVisitors"
        ],
        "ids" : "ga:1234567",
        "metrics" : [
            "ga:activeVisitors"
        ],
        "dimensions" : "ga:pagePath",
        "max-results" : 5
    },
    "rows" : [
        [
            "/fdfds/dsffdsdfssfdsfdsfd",
            "9948"
        ],
        [
            "/jlllk/lkllll",
            "7105"
        ],
        [
            "/sdfsdsdfsdf/things-you-probably-didnt-know-about-disney-parks",
            "4482"
        ],
        [
            "/",
            "4071"
        ],
        [
            "/dsfsdfsdfsdfsd/things-that-happen-when-your-significant-other-is-out-of-tow?bffb=",
            "3858"
        ]
    ],
    "columnHeaders" : [
        {
            "dataType" : "STRING",
                "columnType" : "DIMENSION",
                "name" : "rt:pagePath"
        }, {
            "dataType" : "INTEGER",
                "columnType" : "METRIC",
                "name" : "ga:activeVisitors"
        }
    ],
    "kind" : "analytics#realtimeData",
    "selfLink" : "https://www.googleapis.com/analytics/v3/data/realtime?ids=ga:1234567&dimensions=ga:pagePath&metrics=ga:activeVisitors&sort=-ga:activeVisitors&max-results=5",
    "profileInfo" : {
        "tableId" : "realtime:1234567",
        "accountId" : "1740781",
        "profileId" : "1234567",
        "profileName" : "buzzfeed.com",
        "internalWebPropertyId" : "3070405",
        "webPropertyId" : "UA-1740781-1"
    },
    "id" : "https://www.googleapis.com/analytics/v3/data/realtime?ids=ga:1234567&dimensions=ga:pagePath&metrics=ga:activeVisitors&sort=-ga:activeVisitors&max-results=5",
    "totalResults" : 6937
}
EOF

$res = $analytics->retrieve($req);
ok($res, 'retrieve data');
ok($res->is_success, 'retrieve success');

is($res->num_rows, 5, 'num_rows');
is($res->total_results, 6937, 'total_results');
ok(!$res->contains_sampled_data, 'contains_sampled_data');

my $column_headers = $res->_column_headers;
ok($column_headers, 'column headers');
is($column_headers->[0]->{name}, 'page_path');

my @metrics = $res->metrics;
is_deeply(\@metrics, [ qw(active_visitors) ]);

my @dimensions = $res->dimensions;
is_deeply(\@dimensions, [ qw(page_path) ]);

$rows = $res->rows;
ok($rows, 'rows');
is(@$rows, 5, 'count rows');

