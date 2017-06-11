use strict;
use warnings;

use Test::More 1.302015;
use lib qw(t/lib);
use TDCSTest;

# This test is the only one that does not pass in a schema object. It makes
# sure that we know how to connect and create our own object instead, which
# most users probably do.

# evil globals
my ($schema, $artist, $cd);

$schema = TDCSTest->init_schema();

ok(defined $schema, q{schema object defined});

use Test::DBIx::Class::Schema;

# create a new test object
my $schematest = Test::DBIx::Class::Schema->new({
    # required
    dsn       => $schema->storage->connect_info->[0],
    username  => '',
    password  => '',
    namespace => 'TDCSTest::Schema',
    moniker   => 'Artist',
});

# tell it what to test
$schematest->methods({
    columns => [qw(
        artistid
        personid
        name
    )],

    relations => [qw(
        person
        cds
        cds_90s
    )],

    custom => [
    ],

    resultsets => [
    ],
});

# run the tests
$schematest->run_tests();
