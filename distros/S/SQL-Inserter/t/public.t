use Test2::V0;

use SQL::Inserter qw(simple_insert multi_insert_sql);

subtest 'simple_insert' => sub {
    my @tests = (
        [[{}], ["INSERT INTO table ()\nVALUES ()"]],
        [[{foo=>"bar"}], ["INSERT INTO table (foo)\nVALUES (?)", "bar"]],
        [[[{foo=>"bar"}]], ["INSERT INTO table (foo)\nVALUES (?)", "bar"]],
        [[[{foo=>\"NOW()"},{foo=>"bar",bar=>"foo"}]], ["INSERT INTO table (foo)\nVALUES (NOW()),\n(?)", "bar"]],
        [[{foo=>"bar"}, {duplicates=>'ignore'}], ["INSERT IGNORE INTO table (foo)\nVALUES (?)", "bar"]],
        [[{foo=>"bar"}, {duplicates=>'update'}], ["INSERT INTO table (foo)\nVALUES (?)\nON DUPLICATE KEY UPDATE foo=VALUES(foo)", "bar"]],
        [[{foo=>"bar"}, {null_undef=>1}], ["INSERT INTO table (foo)\nVALUES (?)", "bar"]],
        [[{foo=>undef}], ["INSERT INTO table (foo)\nVALUES (?)", undef]],
        [[{foo=>undef}, {null_undef=>1}], ["INSERT INTO table (foo)\nVALUES (NULL)"]],
        [[[{foo=>"bar"}, {}], {null_undef=>1}], ["INSERT INTO table (foo)\nVALUES (?),\n(NULL)","bar"]],
        [[{}, ], ["INSERT INTO table ()\nVALUES ()"]],
    );
    is([simple_insert('table', @{$_->[0]})], [@{$_->[1]}], "Statements match")
        for @tests;
};

my $dual = "SELECT 1 FROM dual";
subtest 'simple_insert_oracle' => sub {
    my @tests = (
        [[{}, {oracle=>1}], ["INSERT ALL\nINTO table() VALUES()\n$dual"]],
        [[{foo=>"bar"}, {oracle=>1}], ["INSERT ALL\nINTO table(foo) VALUES(?)\n$dual", "bar"]],
        [[[{foo=>\"NOW()"},{foo=>"bar",bar=>"foo"}], {oracle=>1}], ["INSERT ALL\nINTO table(foo) VALUES(NOW())\nINTO table(foo) VALUES(?)\n$dual", "bar"]],
        [[{foo=>"bar"}, {null_undef=>1,oracle=>1}], ["INSERT ALL\nINTO table(foo) VALUES(?)\n$dual", "bar"]],
        [[{foo=>undef}, {oracle=>1}], ["INSERT ALL\nINTO table(foo) VALUES(?)\n$dual", undef]],
        [[{foo=>undef}, {oracle=>1,null_undef=>1}], ["INSERT ALL\nINTO table(foo) VALUES(NULL)\n$dual"]],
        [[[{foo=>"bar"}, {}], {oracle=>1,null_undef=>1}], ["INSERT ALL\nINTO table(foo) VALUES(?)\nINTO table(foo) VALUES(NULL)\n$dual", "bar"]],
    );
    is([simple_insert('table', @{$_->[0]})], [@{$_->[1]}], "Statements match")
        for @tests;
};

subtest 'multi_insert_sql' => sub {
    my @tests = (
        [[], undef],
        [['table'], undef],
        [['table', []], undef],
        [['table', ['col']], "INSERT INTO table (col)\nVALUES (?)"],
        [['table', ['col'], 2], "INSERT INTO table (col)\nVALUES (?),\n(?)"],
        [['table', [qw/col1 col2/]], "INSERT INTO table (col1,col2)\nVALUES (?,?)"],
        [['table', [qw/col1 col2/], 2], "INSERT INTO table (col1,col2)\nVALUES (?,?),\n(?,?)"],
        [['table', ['col'], undef, 'ignore'], "INSERT IGNORE INTO table (col)\nVALUES (?)"],
        [['table', ['col'], 1, 'update'], "INSERT INTO table (col)\nVALUES (?)\nON DUPLICATE KEY UPDATE col=VALUES(col)"],
    );
    is(multi_insert_sql(@{$_->[0]}), $_->[1], "Statements match") for @tests;
};

subtest 'multi_insert_sql oracle' => sub {
    my @tests = (
        [['table', undef, undef, 'oracle'], undef],
        [['table', []], undef],
        [['table', ['col'], undef, 'oracle'], "INSERT ALL\nINTO table(col) VALUES(?)\n$dual"],
        [['table', ['col'], 2, 'oracle'], "INSERT ALL\nINTO table(col) VALUES(?)\nINTO table(col) VALUES(?)\n$dual"],
        [['table', [qw/col1 col2/], 2, 'oracle'], "INSERT ALL\nINTO table(col1,col2) VALUES(?,?)\nINTO table(col1,col2) VALUES(?,?)\n$dual"],
    );
    is(multi_insert_sql(@{$_->[0]}), $_->[1], "Statements match") for @tests;
};

done_testing;
