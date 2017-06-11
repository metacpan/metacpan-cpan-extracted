use strict;
use warnings;

use Test::More 1.302015;
use Test::Exception;
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
    )],

    custom => [
    ],

    # we have missed the 'resultsets' option
    # this used to pass (magically? quietly?) in perl <5.18
    # it now complains with:
    #    Can't use an undefined value as an ARRAY reference at
    #    /opt/xt/xt-perl/lib/site_perl/5.18.1/Test/DBIx/Class/Schema.pm line
    #    221
});

# stop TDCS from doing done_testing on our behalf
$ENV{TEST_AGGREGATE} = 1;

# isa_ok output changed in 0.99
my $isa_expected =
    q{ok 2 - An object of class 'TDCSTest::Schema' isa 'TDCSTest::Schema'};
# if our Test::More is 'old' look for different output from isa_ok
if ($Test::More::VERSION < 0.99) {
    $isa_expected = q{ok 2 - The object isa TDCSTest::Schema};
}

use Test::Builder::Tester tests=>2;
test_out(
    q{ok 1 - use TDCSTest::Schema;},
    $isa_expected,
    q{ok 3 - The record object is a ::Artist},
    q{ok 4 - 'artistid' column defined in result_source},
    q{ok 5 - 'artistid' column exists in database},
    q{ok 6 - 'personid' column defined in result_source},
    q{ok 7 - 'personid' column exists in database},
    q{ok 8 - 'name' column defined in result_source},
    q{ok 9 - 'name' column exists in database},
    q{ok 10 - related source for 'person' exists},
    q{ok 11 - self.personid valid for 'person' relationship},
    q{ok 12 - foreign.personid valid for 'person' relationship},
    q{ok 13 - related source for 'cds' exists},
    q{ok 14 - self.artistid valid for 'cds' relationship},
    q{ok 15 - foreign.artistid valid for 'cds' relationship},
    q{ok 16 # skip no custom methods},
    q{ok 17 # skip no resultsets methods},
    q{ok 18 - test survives with missing method in config},
);

test_err(
    q{# 'relations' method defined in Artist but untested: cds_90s}
);

# run the tests
lives_ok {
    $schematest->run_tests();
} q{test survives with missing method in config};

test_test(title => 'test output as expected with missing method', skip_err => 0);

# we need to explicitly say we're done
done_testing;
