use strict;
use warnings;
use Test::More;

use lib "lib";
use Test::DBIC::ExpectedQueries;


my $queries = Test::DBIC::ExpectedQueries->new({
    schema => "don't hit anything that uses ->schema and we'll be fine",
});

sub query {
    my ($table, $operation) = @_;
    return Test::DBIC::ExpectedQueries::Query->new({
        sql         => "$operation on $table",
        stack_trace => "not under test",
        table       => $table,
        operation   => $operation,
    });
}



note "Test queries vs expected";
#
# puff
#  select 2
# magic
#  insert 2
#  select 3
# dragon
#  delete 1

# * Expect
# ok  - puff select 2
# not - puff insert > 0
# ok - magic insert < 3
# not - no mention of magic select
# not - dragon, no mention of

$queries->queries([
    query("puff", "select"),
    query("puff", "select"),
    query("magic", "insert"),
    query("magic", "insert"),
    query("magic", "select"),
    query("magic", "select"),
    query("magic", "select"),
    query("dragon", "delete"),
    Test::DBIC::ExpectedQueries::Query->new({
        sql         => "create table abc",
        stack_trace => "",
    }),
]);

my $failure = $queries->check_table_operation_counts({
    puff  => { select => 2 },
    magic => { insert => "> 0", stack_trace => 1 },
});

is(
    $failure,
    "* Table: dragon
Expected '0' deletes for table 'dragon', got '1'
Actually executed SQL queries on table 'dragon':
SQL: (delete on dragon)

* Table: magic
Expected '0' selects for table 'magic', got '3'
Actually executed SQL queries on table 'magic':
SQL: (insert on magic)
     not under test
SQL: (insert on magic)
     not under test
SQL: (select on magic)
     not under test
SQL: (select on magic)
     not under test
SQL: (select on magic)
     not under test

",
    "Correctly identified all discrepancies",
);

is(
    $queries->unknown_warning,
    "

Warning: unknown queries:
SQL: (create table abc)
",
    "Found unknown queries",
);



note "Check it works to run many times and then checking";
$queries->queries([
    query("puff", "select"),
]);
$failure = $queries->check_table_operation_counts({
    puff  => { select => 1 },
});

is($failure, "", "Re-setting queries re-sets the stats");


###JPL: test all $expected_queries, even if there's no query for one


done_testing();
