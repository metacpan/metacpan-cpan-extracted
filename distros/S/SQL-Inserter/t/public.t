use Test2::V0;

use SQL::Inserter qw(simple_insert multi_insert_sql);

subtest 'simple_insert' => sub {
    my @tests = (
        [['table', {}], ["INSERT INTO table ()\nVALUES ()"]],
        [['table', {foo=>"bar"}], ["INSERT INTO table (foo)\nVALUES (?)", "bar"]],
        [['table', [{foo=>"bar"}]], ["INSERT INTO table (foo)\nVALUES (?)", "bar"]],
        [['table', [{foo=>\"NOW()"},{foo=>"bar",bar=>"foo"}]], ["INSERT INTO table (foo)\nVALUES (NOW()),\n(?)", "bar"]],
        [['table', {foo=>"bar"}, {duplicates=>'ignore'}], ["INSERT IGNORE INTO table (foo)\nVALUES (?)", "bar"]],
        [['table', {foo=>"bar"}, {duplicates=>'update'}], ["INSERT INTO table (foo)\nVALUES (?)\nON DUPLICATE KEY UPDATE foo=VALUES(foo)", "bar"]],
        [['table', {foo=>"bar"}, {null_undef=>1}], ["INSERT INTO table (foo)\nVALUES (?)", "bar"]],
        [['table', {foo=>undef}], ["INSERT INTO table (foo)\nVALUES (?)", undef]],
        [['table', {foo=>undef}, {null_undef=>1}], ["INSERT INTO table (foo)\nVALUES (NULL)"]],
        [['table', [{foo=>"bar"}, {}], {null_undef=>1}], ["INSERT INTO table (foo)\nVALUES (?),\n(NULL)","bar"]],
    );
    foreach my $test (@tests) {
        is([simple_insert(@{$test->[0]})], [@{$test->[1]}], "Statements match");
    }
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
    foreach my $test (@tests) {
        is(multi_insert_sql(@{$test->[0]}), $test->[1], "Statements match");
    }
};

done_testing;
