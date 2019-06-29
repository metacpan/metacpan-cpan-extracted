#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 2;

use Sport::Analytics::NHL;
use Sport::Analytics::NHL::Normalizer;
use Sport::Analytics::NHL::Vars qw($IS_AUTHOR);
use Sport::Analytics::NHL::Test;
use Storable;

$ENV{HOCKEYDB_DEBUG} = $IS_AUTHOR;
my @merged = Sport::Analytics::NHL::merge({}, {reports_dir => 't/data/'}, 201120010);
my $boxscore = retrieve $merged[0];
$ENV{HOCKEYDB_DATA_DIR} = 't/data';

normalize_boxscore($boxscore);
test_normalized_boxscore($boxscore);

is($TEST_COUNTER->{Curr_Test}, 11650, 'team and roster all tested');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');
