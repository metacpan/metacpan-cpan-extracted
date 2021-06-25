#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}


use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use SQLite::KeyValueStore::Simple;
use Test::SQL::Schema::Versioned;
use Test::WithDB::SQLite;

sql_schema_spec_ok(
    $SQLite::KeyValueStore::Simple::db_schema_spec,
    Test::WithDB::SQLite->new,
);
done_testing;
