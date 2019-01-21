use strict;
use warnings;
use utf8;

use lib qw(lib t/lib .);

use t::Util;
use Test::More;

my $db = create_testdb();
$db->dbh->do(q{
    INSERT INTO test_table (id, name) VALUES (1, 'Apple'), (2, 'Banana'), (3, 'Coconut')
});

subtest 'search_named_hashref' => sub {
    my $row = $db->single_named_hashref(q{
        SELECT * FROM test_table WHERE id = :id
    }, +{ id => 2 }, 'test_table');
    is ref $row, 'HASH';
    is_deeply $row, { id => 2, name => 'Banana' };
};

subtest 'does not affect original method' => sub {
    my $row = $db->single_named(q{
        SELECT * FROM test_table WHERE id = :id
    }, +{ id => 2 }, 'test_table');
    is ref $row, 'TestDB::Model::Row::TestTable';
    is_deeply $row->get_columns, { id => 2, name => 'Banana' };
};

done_testing;
