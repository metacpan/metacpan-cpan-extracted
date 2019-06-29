#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Vars qw($MONGO_DB $REPORTS_DIR);
use Sport::Analytics::NHL;

plan tests => $ENV{HOCKEYDB_NODB} || !$MONGO_DB ? 4 : 5;

ok(hdb_version(), 'version defined');

my $hdb = Sport::Analytics::NHL->new({no_database => 1});
isa_ok($hdb, 'Sport::Analytics::NHL');
$hdb = Sport::Analytics::NHL->new({no_database => 1, reports_dir => '/tmp'});
is($ENV{HOCKEYDB_REPORTS_DIR}, '/tmp', 'custom data dir set');
is($REPORTS_DIR, '/tmp', 'and propagated into the global variable');
if (! $ENV{HOCKEYDB_NODB} && $MONGO_DB) {
	$hdb = Sport::Analytics::NHL->new({});
	isa_ok($hdb->{db}, 'Sport::Analytics::NHL::DB');
}
