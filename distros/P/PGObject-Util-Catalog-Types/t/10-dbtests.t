use PGObject::Util::Catalog::Types qw(get_attributes);
use Test::More;
use DBI;

plan skip_all => 'Not set up for db tests' unless $ENV{DB_TESTING};
plan tests => 31;

# SETUP
my $dbh1 = DBI->connect('dbi:Pg:dbname=postgres', 'postgres');
$dbh1->do('CREATE DATABASE pgobject_test_db') if $dbh1;

my $dbh = DBI->connect('dbi:Pg:dbname=pgobject_test_db', 'postgres');
$dbh->do("CREATE SCHEMA $_") for qw(typetest viewtest tabletest);

$dbh->do('CREATE TYPE typetest.footype AS (
    foo int,
    bar text,
    baz bigint,
    barbaz varchar(32)
)');

$dbh->do('CREATE TABLE tabletest.footable OF typetest.footype');

$dbh->do('CREATE VIEW viewtest.fooview AS SELECT * FROM tabletest.footable');

my @cols = (
   { name => 'foo',    type => 'int4' },
   { name => 'bar',    type => 'text' },
   { name => 'baz',    type => 'int8' },
   { name => 'barbaz', type => 'varchar' },
);

# TESTS

my @typecols = get_attributes(
    dbh        => $dbh,
    typename   => 'footype',
    typeschema => 'typetest'
);

is(scalar @typecols, 4, 'Correct number of cols returned for type');

is($typecols[$_]->{attname}, $cols[$_]->{name}, "Column $_, correct name, type")
   for 1 ..  scalar @typecols;

is($typecols[$_]->{atttype}, $cols[$_]->{type}, "Column $_, correct name, type")
   for 1 ..  scalar @typecols;

my @tablecols = get_attributes(
    dbh        => $dbh,
    typename   => 'footype',
    typeschema => 'typetest'
);

is(scalar @tablecols, 4, 'Correct number of cols returned for table');

is($tablecols[$_]->{attname}, $cols[$_]->{name}, 
   "Column $_, correct name, table")
   for 1 ..  scalar @tablecols;

is($tablecols[$_]->{atttype}, $cols[$_]->{type}, 
   "Column $_, correct name, table")
   for 1 ..  scalar @typecols;

my @viewcols = get_attributes(
    dbh        => $dbh,
    typename   => 'footype',
    typeschema => 'typetest'
);

is(scalar @viewcols, 4, 'Correct number of cols returned for type');

is($viewcols[$_]->{attname}, $cols[$_]->{name}, "Column $_, correct name, view")
   for 1 ..  scalar @viewcols;

is($viewcols[$_]->{atttype}, $cols[$_]->{type}, "Column $_, correct name, view")
   for 1 ..  scalar @viewcols;


# CLEANUP
$dbh->disconnect;
$dbh1->do('DROP DATABASE pgobject_test_db');
