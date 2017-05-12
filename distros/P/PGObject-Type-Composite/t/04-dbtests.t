package testpkg;
use PGObject::Type::Composite;

sub _get_schema{'typetest'};
sub _get_typename{'footype'}

package main;

use Test::More;
use DBI;

plan skip_all => 'Not set up for db tests' unless $ENV{DB_TESTING};
plan tests => 8;

# SETUP
my $dbh1 = DBI->connect('dbi:Pg:dbname=postgres', 'postgres');
$dbh1->do('CREATE DATABASE pgobject_test_db') if $dbh1;

my $dbh = DBI->connect('dbi:Pg:dbname=pgobject_test_db', 'postgres');
$dbh->do("CREATE SCHEMA $_") for qw(typetest viewtest tabletest);

$dbh->do('CREATE TYPE typetest.footype AS (
    foo int,
    bar text,
    baz bigint
)');

#TESTS

my @cols2;
ok(@cols2 = testpkg->initialize(dbh => $dbh), 'Initialized class');

is(scalar @cols2, 3, 'got three columns');

my $string = "(foo,3,4333)";
my $string2 = "(bar,133,444)";
my $string3 = q(("foo,bar",133,42222));

ok(my $obj1 = testpkg->from_db($string), 'First object deserialized');
ok(my $obj2 = testpkg->from_db($string2), 'First object deserialized');
ok(my $obj3 = testpkg->from_db($string3), 'First object deserialized');

is($obj1->to_db->{value}, $string, 'First object serialized correctly');
is($obj2->to_db->{value}, $string2, 'Second object serialized correctly');
is($obj3->to_db->{value}, $string3, 'Third object serialized correctly');

# CLEANUP
$dbh->disconnect;

$dbh1->do('DROP DATABASE pgobject_test_db');

