#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 10;

use JSON;
use Storable;

use Sport::Analytics::NHL::Test;
use Sport::Analytics::NHL;

use t::lib::Util;

test_env();
$ENV{HOCKEYDB_DATA_DIR} = 't/tmp/data';
system(qw(mkdir -p t/tmp/));
system(qw(cp -a t/data t/tmp/));
system('find t/tmp -name "*.storable" -delete');
$ENV{HOCKEYDB_NODB} = 1;
$ENV{HOCKEYDB_DEBUG} = 0;
my $nhl = Sport::Analytics::NHL->new();
my $storable = ($nhl->normalize({}, 201120010))[0];

is($storable, 't/tmp/data/2011/0002/0010/normalized.storable', 'return path correct');
ok(-f $storable, 'file exists');
my $json = $storable; $json =~ s/storable/json/;
ok(-f $json, 'json exists');

my $boxscore = retrieve $storable;
test_normalized_boxscore($boxscore);
is($TEST_COUNTER->{Curr_Test}, 11534, 'team and roster all tested');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');
$storable = ($nhl->normalize({}, 193020010))[0];

is($storable, 't/tmp/data/1930/0002/0010/normalized.storable', 'return path correct');
ok(-f $storable, 'file exists');
$json = $storable; $json =~ s/storable/json/;
ok(-f $json, 'json exists');
$boxscore = retrieve $storable;
test_normalized_boxscore($boxscore);
is($TEST_COUNTER->{Curr_Test}, 12407, 'team and roster all tested');
is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], 'all ok');

END {
	system(qw(rm -rf t/tmp/data));
}
