use strict;
use warnings;
use utf8;

use lib qw(lib t/lib .);

use t::Util;
use Test::More;

my $db = create_testdb();

subtest 'insert_hashref' => sub {
    my $row = $db->insert_hashref(test_table => +{
        id => 101,
        name => 'Banana',
    });
    is ref $row, 'HASH';
    is_deeply $row, { id => 101, name => 'Banana' };
};

subtest 'does not affect original method' => sub {
    my $row = $db->insert(test_table => +{
        id => 102,
        name => 'Coconut',
    });
    is ref $row, 'TestDB::Model::Row::TestTable';
    is_deeply $row->get_columns, { id => 102, name => 'Coconut' };
};

done_testing;
