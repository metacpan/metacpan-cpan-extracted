use strict;
use warnings;

use Test::Tester;
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
    moniker   => 'Artist',
});

# tell it what to test
$schematest->methods({
    columns => [
    ],
    
    relations => [qw(
        cds_90s
    )],

    custom => [
    ],

    resultsets => [
    ],
});

# stop TDCS from doing done_testing on our behalf
$ENV{TEST_AGGREGATE} = 1;

# run the tests, but capture the results...
my ( $premature, @results ) = run_tests(
    sub {
        $schematest->run_tests();
    }
);

# ... so we can check for todos...
ok $results[5]->{type} eq 'todo'
    && $results[5]->{reason} eq 'skipping column tests for CODE defined condition',
    'coderef condition was skipped with TODO';

# ... and skips
ok $results[6]->{type} eq 'skip'
    && $results[6]->{reason} eq 'no custom methods',
    'custom method test was skipped';
ok $results[7]->{type} eq 'skip'
    && $results[7]->{reason} eq 'no resultsets methods',
    'custom method test was skipped';

# we need to explicitly say we're done
done_testing;
