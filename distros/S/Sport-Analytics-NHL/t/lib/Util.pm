package t::lib::Util;

use v5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More;

use POSIX qw(strftime);

use Sport::Analytics::NHL::Config qw(:all);
use Sport::Analytics::NHL::Vars qw($IS_AUTHOR);
use Sport::Analytics::NHL::Test qw($TEST_COUNTER);
use Sport::Analytics::NHL::Util;

use Storable qw(dclone store retrieve);

use Data::Dumper;

use parent 'Exporter';

our @EXPORT = qw(
    test_env summarize_tests
);

my $TEST_DB = 'hockeytest1';

sub test_env (;$) {

	my $dbname = shift || $TEST_DB;

	$ENV{HOCKEYDB_DBNAME}   = $dbname;
	$ENV{HOCKEYDB_DEBUG} = $IS_AUTHOR;
	$ENV{HOCKEYDB_DATA_DIR} = 't/data';
	$ENV{HOCKEYDB_TEST}     = 1;
}

sub summarize_tests () {
	ok($TEST_COUNTER->{Curr_Test}, "$TEST_COUNTER->{Curr_Test} custom tests run");
	is($TEST_COUNTER->{Curr_Test}, $TEST_COUNTER->{Test_Results}[0], "All $TEST_COUNTER->{Curr_Test} custom tests passed");
}

1;
