use strict;
use warnings;
use Test::Builder::Tester tests => 4;
use Test::More 1.302015;

use Test::DBIx::Class::Schema;

use lib 't/lib';
use UnexpectedTest;

# evil globals
my ($schema);

$schema = UnexpectedTest->init_schema();
isa_ok($schema, 'UnexpectedTest::Schema');

# create a new test object
my $schematest = Test::DBIx::Class::Schema->new({
    # required
    schema    => $schema,
    namespace => 'UnexpectedTest::Schema',
    moniker   => 'SpanishInquisition',
});
isa_ok($schematest, 'Test::DBIx::Class::Schema');

# setup columns to test
$schematest->methods({
    columns => [qw(id name)],
    relations => [],
    custom => [],
    resultsets => [],
});

# isa_ok output changed in 0.99
my $isa_expected =
    q{ok 2 - An object of class 'UnexpectedTest::Schema' isa 'UnexpectedTest::Schema'};
# if our Test::More is 'old' look for different output from isa_ok
if ($Test::More::VERSION < 0.99) {
    $isa_expected = q{ok 2 - The object isa UnexpectedTest::Schema};
}

my @expected_out = (
    q{ok 1 - use UnexpectedTest::Schema;},
    $isa_expected,
    q{ok 3 - The record object is a ::SpanishInquisition},
    q{ok 4 - 'id' column defined in result_source},
    q{ok 5 - 'id' column exists in database},
    q{ok 6 - 'name' column defined in result_source},
    q{ok 7 - 'name' column exists in database},
    q{ok 8 # skip no relations methods},
    q{ok 9 # skip no custom methods},
    q{ok 10 # skip no resultsets methods},
    q{ok 11 # skip no relations methods},
);

# we really need to work out why this is happening ... and MAKE IT STOP
# I think that Test::Builder::Tester plans are getting mixed up with the
# actual test plans ...
if (1) {
    push @expected_out,
         q{not ok 12 - planned to run 4 but done_testing() expects 11}
    ;
}

#
## All's good - no unexpected columns
NO_SURPRISES: {
    test_out(
        @expected_out,
    );

    $schematest->run_tests();

    test_test(title => 'test output as expected for passing case', skip_err => 1);
}

FORGOT_TO_TEST: {
    # stop testing one of the columns we know we have defined
    $schematest->methods({
        columns     => [qw(id)],
        relations   => [],
        custom      => [],
        resultsets  => [],
    });

    test_out(
        q{ok 1 - use UnexpectedTest::Schema;},
        $isa_expected,
        q{ok 3 - The record object is a ::SpanishInquisition},
        q{ok 4 - 'id' column defined in result_source},
        q{ok 5 - 'id' column exists in database},
        q{ok 6 # skip no relations methods},
        q{ok 7 # skip no custom methods},
        q{ok 8 # skip no resultsets methods},
        q{ok 9 # skip no relations methods},
    );

    test_err(
        q{# 'columns' method defined in SpanishInquisition but untested: name},
    );

    $schematest->run_tests();

    test_test(title => 'test output as expected for untested column');
}

# DO NOT USE: done_testing;
