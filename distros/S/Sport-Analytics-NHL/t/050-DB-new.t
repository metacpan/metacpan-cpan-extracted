#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Vars qw($MONGO_DB);
use Sport::Analytics::NHL::DB;

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
	plan skip_all => 'Mongo not defined';
	exit;
}
plan tests => 8;

my $db = Sport::Analytics::NHL::DB->new();
isa_ok($db, 'Sport::Analytics::NHL::DB');
isa_ok($db->{dbh}, 'MongoDB::Database');
isa_ok($db->{client}, 'MongoDB::MongoClient');
is($db->{dbname}, $MONGO_DB, 'mongo db name set');

$db = Sport::Analytics::NHL::DB->new('hockeytest');
isa_ok($db, 'Sport::Analytics::NHL::DB');
isa_ok($db->{dbh}, 'MongoDB::Database');
isa_ok($db->{client}, 'MongoDB::MongoClient');
is($db->{dbname}, 'hockeytest', 'custom mongo db name set');
