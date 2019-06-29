#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 31;

use Sport::Analytics::NHL;
use Sport::Analytics::NHL::Normalizer;
use Storable;

my @merged = Sport::Analytics::NHL::merge({}, {reports_dir => 't/data/'}, 201120010);
my $boxscore = retrieve $merged[0];

Sport::Analytics::NHL::Normalizer::normalize_result($boxscore);
is_deeply($boxscore->{result}, [0,2], 'result correct');
Sport::Analytics::NHL::Normalizer::normalize_header($boxscore);
like($boxscore->{date}, qr/^\d{8}$/, 'game date set correctly');
is($boxscore->{location}, 'TD GARDEN', 'location correct');
for my $field (qw(_id attendance last_updated month date ot start_ts stop_ts stage season season_id)) {
	like($boxscore->{$field}, qr/^\d+$/, "$field a number");
}
is_deeply($boxscore->{sources}, {RO => 1, PL => 1, GS => 1, ES => 1, TH => 1, TV => 1, BS => 1,}, 'all sources');
is_deeply($boxscore->{_score}, [1, 4], 'score correct');
use Data::Dumper;
@merged = Sport::Analytics::NHL::merge({}, {reports_dir => 't/data/'}, 193020010);
$boxscore = retrieve $merged[0];

Sport::Analytics::NHL::Normalizer::normalize_result($boxscore);
is_deeply($boxscore->{result}, [0,2], 'result correct');
Sport::Analytics::NHL::Normalizer::normalize_header($boxscore);
like($boxscore->{date}, qr/^\d{8}$/, 'game date set correctly');
for my $field (qw(_id attendance last_updated month date ot start_ts stop_ts stage season season_id)) {
	like($boxscore->{$field}, qr/^\-?\d+$/, "$field a number");
}
is_deeply($boxscore->{sources}, {BS => 1,}, 'all sources');
is_deeply($boxscore->{_score}, [0,1], 'score correct');
