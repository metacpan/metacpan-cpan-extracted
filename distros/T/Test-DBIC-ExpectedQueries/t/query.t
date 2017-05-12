
use strict;
use warnings;
use Test::More;

use lib "lib";
use Test::DBIC::ExpectedQueries::Query;


note "*** SQL queries parsed correctly";

sub test_parse {
    my ($sql, $operation, $table) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $query = Test::DBIC::ExpectedQueries::Query->new({
        sql         => $sql,
        stack_trace => "not under test",
    });
    is($query->operation, $operation, "Correct ->operation for $operation");
    is($query->table, $table, "Correct ->table for $operation");
}

note "SELECT";
test_parse("Select * from file", "select", "file");
test_parse("Select * from metric_value", "select", "metric_value");
test_parse("Select * from 'file'", "select", "file");

note "INSERT";
test_parse("insert into file ('id') values (1)", "insert", "file");
test_parse("insert into `file` ('id') values (1)", "insert", "file");

note "UPDATE";
test_parse("update file set id = 2 where id = 4", "update", "file");
test_parse('update "file" set id = 2 where id = 4', "update", "file");

note "DELETE";
test_parse("delete from other_db.file where id = 4", "delete", "other_db.file");
test_parse("delete from 'other_db.file' where id = 4", "delete", "other_db.file");



done_testing();
