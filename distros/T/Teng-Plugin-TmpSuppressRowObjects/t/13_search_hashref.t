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

subtest 'search_hashref (rows)' => sub {
    my @rows = $db->search_hashref(test_table => +{ id => [2, 3] }, +{ order_by => 'id ASC' });
    is ref $rows[0], 'HASH';
    is_deeply \@rows, [
        { id => 2, name => 'Banana' },
        { id => 3, name => 'Coconut' },
    ];
};

subtest 'search_hashref (iterator)' => sub {
    my $itr = $db->search_hashref(test_table => +{ id => [2, 3] }, +{ order_by => 'id ASC' });

    my $row = $itr->next;
    is ref $row, 'HASH';
    is_deeply $row, { id => 2, name => 'Banana' };

    $row = $itr->next;
    is ref $row, 'HASH';
    is_deeply $row, { id => 3, name => 'Coconut' };

    ok !$itr->next;
};

subtest 'does not affect original method' => sub {
    my @rows = $db->search(test_table => +{ id => [2, 3] }, +{ order_by => 'id ASC' });
    is ref $rows[0], 'TestDB::Model::Row::TestTable';
    is_deeply [ map { $_->get_columns } @rows ], [
        { id => 2, name => 'Banana' },
        { id => 3, name => 'Coconut' },
    ];
};

done_testing;
