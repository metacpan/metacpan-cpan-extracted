
use strict;
use warnings;
use Test::More;

use lib "lib";
use Test::DBIC::ExpectedQueries::Query;


note "*** SQL queries parsed correctly";

sub test_parse {
    my ($sql, $operation, $table, $report_subselect_tables) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $report_subselect_tables ||= 0;

    my $query = Test::DBIC::ExpectedQueries::Query->new({
        sql                     => $sql,
        stack_trace             => "not under test",
        report_subselect_tables => $report_subselect_tables,
    });
    my $display_operation = $operation // "<None>";
    is($query->operation, $operation, "Correct ->operation for $display_operation");
    is($query->table, $table, "Correct ->table for $display_operation");
}


subtest "Simple operations" => sub {
    subtest "SELECT" => sub {
        test_parse("Select * from file", "select", "file");
        test_parse("Select * from metric_value", "select", "metric_value");
        test_parse("Select * from 'file'", "select", "file");
    };

    subtest "INSERT" => sub {
        test_parse("insert into file ('id') values (1)", "insert", "file");
        test_parse("insert into `file` ('id') values (1)", "insert", "file");
    };

    subtest "UPDATE" => sub {
        test_parse("update file set id = 2 where id = 4", "update", "file");
        test_parse('update "file" set id = 2 where id = 4', "update", "file");
    };

    subtest "DELETE" => sub {
        test_parse("delete from other_db.file where id = 4", "delete", "other_db.file");
        test_parse("delete from 'other_db.file' where id = 4", "delete", "other_db.file");
    };
};


subtest "Sub selects" => sub {
    test_parse("SELECT abc, def from (select * from file)", "select", "select");

    note "Sub-select";
    test_parse("SELECT abc, def from (select * from file)", "select", "file", 1);

    note "Nested sub-selects";
    test_parse(
        "SELECT abc, def from (select * from (select * from (select * from file)))",
        "select",
        "file",
        1,
    );

    note "Nested sub-selects, with eventually no identifiable table at the core";
    test_parse(
        "SELECT abc, def from (select * from (select * from (select 'Just a value')))",
        undef,
        undef,
        1,
    );
};

subtest "Issue 6" => sub {
    note "Actal query reported";
    test_parse(
        q|
    (SELECT me.id, me.req_id, me.version, me.name FROM (
      SELECT me.id, me.req_id, me.version, me.name FROM tablename me WHERE ( req_id = ? )  ORDER BY version DESC
    ) me WHERE ROWNUM <= ?
|,
        "select",
        "tablename",
        1,
    );
};




done_testing();
