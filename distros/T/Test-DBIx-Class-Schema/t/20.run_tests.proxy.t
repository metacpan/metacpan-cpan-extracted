use strict;
use warnings;

use Test::More 1.302015;
use lib qw(t/lib);
use TDCSTest;

# evil globals
my ($schema, $artist, $cd);

$schema = TDCSTest->init_schema();

ok(defined $schema, q{schema object defined});

use Test::DBIx::Class::Schema;

# create a new test object
my $schematest = Test::DBIx::Class::Schema->new({
    # required
    schema    => $schema,
    namespace => 'TDCSTest::Schema',
    moniker   => 'Audiophile',
});

# tell it what to test
$schematest->methods({
    columns => [qw(
        personid
        first_name
        employee_count
        name
        shopid
    )],

    relations => [qw(
        person
        cdshop_audiophiles
        cds
        works_at
    )],

    custom => [
    ],

    resultsets => [
    ],
});

# run the tests
$schematest->run_tests();
