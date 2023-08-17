use Test2::V0;

use SQL::Inserter;

subtest '_row_placeholders' => sub {
    my @tests = (
        [[{foo=>"bar",bar=>"foo"}, [qw/foo bar/]],["(?,?)", "bar", "foo"]],
        [[{foo=>"bar"}, [qw/foo bar/]],["(?,?)", "bar", undef]],
        [[{}, [qw/foo bar/]],["(?,?)", undef, undef]],
        [[{bar=>\"NOW()"}, [qw/foo bar/]],["(?,NOW())", undef]],
        [[{foo=>"bar",bar=>"foo"}, [qw/foo bar/], 1],["(?,?)", "bar", "foo"]],
        [[{foo=>"bar"}, [qw/foo bar/], 1],["(?,NULL)", "bar"]],
        [[{}, [qw/foo bar/], 1],["(NULL,NULL)"]],
        [[{bar=>\"NOW()"}, [qw/foo bar/], 1],["(NULL,NOW())"]],
    );
    foreach my $test (@tests) {
        is([SQL::Inserter::_row_placeholders(@{$test->[0]})], [@{$test->[1]}], "Placeholders match");
    }
};

subtest '_on_duplicate_key_update' => sub {
    my @tests = (
        [[qw/foo bar/], "\nON DUPLICATE KEY UPDATE foo=VALUES(foo),bar=VALUES(bar)"],
        [["foo"], "\nON DUPLICATE KEY UPDATE foo=VALUES(foo)"],
        [[], "\nON DUPLICATE KEY UPDATE "],
    );
    foreach my $test (@tests) {
        is(SQL::Inserter::_on_duplicate_key_update($test->[0]), $test->[1], "Clauses match");
    }
};

subtest '_create_insert_sql' => sub {
    my @tests = (
        [['table', [qw/foo bar/], '(?,?)'], "INSERT INTO table (foo,bar)\nVALUES (?,?)"],
        [['table', [qw/foo bar/], '(?,?)', 'ignore'], "INSERT IGNORE INTO table (foo,bar)\nVALUES (?,?)"],
        [['table', [qw/foo bar/], '(?,?)', 'update'], "INSERT INTO table (foo,bar)\nVALUES (?,?)\nON DUPLICATE KEY UPDATE foo=VALUES(foo),bar=VALUES(bar)"],
        [['table', ["foo"], '(?)'], "INSERT INTO table (foo)\nVALUES (?)"],
    );
    foreach my $test (@tests) {
        is(SQL::Inserter::_create_insert_sql(@{$test->[0]}), $test->[1], "Statements match");
    }
};

done_testing;
