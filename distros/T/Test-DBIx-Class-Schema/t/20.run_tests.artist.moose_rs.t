use strict;
use warnings;

use Test::More 1.302015;
use lib qw(t/lib);
use TDCSTest;

# This test checks that this distribution works resultset classes that make use
# of Moose as DBIC's docs suggest (see
# https://metacpan.org/pod/DBIx::Class::ResultSet#CUSTOM-ResultSet-CLASSES-THAT-USE-Moose)

my $schema = TDCSTest->init_schema();
isa_ok($schema, 'TDCSTest::Schema');

use Test::DBIx::Class::Schema;

# create a new test object
my $schematest = Test::DBIx::Class::Schema->new({
    # required
    schema    => $schema,
    namespace => 'TDCSTest::Schema',
    moniker   => 'Artist',
});

# Set the resultset class
$schematest->{schema}->source('Artist')
    ->resultset_class('TDCSTest::ResultSet::ArtistMoose');

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
    )],

    custom => [
    ],

    resultsets => [qw/
        artists
    /],
});

# run the tests
$schematest->run_tests();
