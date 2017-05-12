use strict;
use warnings;

use Test::More;

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        plan skip_all => "These tests are for release testing";
    }
}

use lib 'inc';

use FindBin qw( $Bin );
use List::AllUtils qw( max );
use Path::Class qw( dir );
use Pg::DatabaseManager::TestMigrations qw( test_migrations);
use Silki::DatabaseManager;

my $testdir = dir($Bin);

my $min_version = 4;
my $max_version = max map { /\.v(\d+)/; $1 } glob "$testdir/*.v*";

test_migrations(
    class            => 'Silki::DatabaseManager',
    db_name          => 'SilkiMigrationTest',
    min_version      => $min_version,
    max_version      => $max_version,
    sql_file_pattern => $testdir->file('Silki.sql.v%{version}')->stringify(),
    db_encoding      => 'UTF-8',
);

done_testing();
