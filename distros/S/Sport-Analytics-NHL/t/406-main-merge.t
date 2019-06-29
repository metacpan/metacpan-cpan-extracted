#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use JSON;
use Storable;

use Sport::Analytics::NHL::Test;
use Sport::Analytics::NHL;

use t::lib::Util;

plan qw(no_plan);

test_env();
$ENV{HOCKEYDB_DATA_DIR} = 't/tmp/data';
system(qw(mkdir -p t/tmp/));
system(qw(cp -a t/data t/tmp/));
$ENV{HOCKEYDB_NODB} = 1;

my $nhl = Sport::Analytics::NHL->new();
my $storable = ($nhl->merge({}, 201120010))[0];

is($storable, 't/tmp/data/2011/0002/0010/merged.storable', 'return path correct');
ok(-f $storable, 'file exists');
my $boxscore = retrieve $storable;
test_merged_boxscore($boxscore);
is($TEST_COUNTER->{Curr_Test}, 5012, 'team and roster all tested');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');
$storable = ($nhl->merge({}, 193020010))[0];

is($storable, 't/tmp/data/1930/0002/0010/merged.storable', 'return path correct');
ok(-f $storable, 'file exists');
$boxscore = retrieve $storable;
test_merged_boxscore($boxscore);
is($TEST_COUNTER->{Curr_Test}, 5467, 'team and roster all tested');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');

END {
	system(qw(rm -rf t/tmp/data));
}
