use strict;
use warnings;
use t::Utils;
use Mock::Basic;
use Test::More;
Mock::Basic->load_plugin('SearchBySQLAbstractMore::Pager::Count');

my $dbh = t::Utils->setup_dbh;
$dbh->do('DROP TABLE IF EXISTS mock_basic');
$dbh->do('DROP TABLE IF EXISTS mock_basic2');

my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

$db->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});
$db->insert('mock_basic',{
    id   => 2,
    name => 'python',
});
$db->insert('mock_basic',{
    id   => 3,
    name => 'java',
});

$db->insert('mock_basic2',{
    id   => 1,
    mock_basic_id => 1,
    name => 'perl2',
});
$db->insert('mock_basic2',{
    id   => 2,
    mock_basic_id => 2,
    name => 'python2',
});
$db->insert('mock_basic2',{
    id   => 3,
    mock_basic_id => 3,
    name => 'java2',
});

subtest 'search_with_having' => sub {
    my ($rows, $pager) = $db->search_by_sql_abstract_more_with_pager('mock_basic',{
    }, {
        -columns  => ['id % 2 as id_mod'],
        -group_by => ['id % 2'],
        # DBD::SQLite cannot work well {'<' => 1}
        -having   => [{id_mod => { '<' => \'1' }}],
        -order_by => ['id_mod'],
        -page     => 1,
        -rows     => 2,
       });
    is ref $pager, 'Data::Page';
    is scalar @$rows, 1, 'total_entries';

    my $row = $rows->[0];
    isa_ok $row, 'Teng::Row';

    is $row->get_column('id_mod'), '0';

    is $pager->current_page, 1;
    is $pager->total_entries, 1;
    is $pager->first, 1;
    is $pager->last, 1;

};

subtest 'search_with_group_by' => sub {
    my ($rows, $pager) = $db->search_by_sql_abstract_more_with_pager('mock_basic',{
    }, {
        -columns => ['id % 2 as id_mod'],
        -from => ['mock_basic'],
        -group_by => ['id % 2'],
        -order_by => ['id_mod'],
        -page     => 1,
        -rows     => 2,
       });

    is ref $pager, 'Data::Page';
    is scalar @$rows, 2, 'total_entries';

    my $row = $rows->[0];
    isa_ok $row, 'Teng::Row';

    is $row->get_column('id_mod'), '0';

    my $row2 = $rows->[1];
    isa_ok $row2, 'Teng::Row';

    is $row2->get_column('id_mod'), '1';

    is $pager->current_page, 1;
    is $pager->total_entries, 2;
    is $pager->first, 1;
    is $pager->last, 2;

};

subtest 'search with join' => sub {
    my ($rows, $pager) = $db->search_by_sql_abstract_more_with_pager('mock_basic',{
    }, {
        -columns => ['a.id', 'b.name'],
        -from => [-join =>
                  'mock_basic|a',
                  'a.id=b.mock_basic_id',
                  'mock_basic2|b',
                 ],
        -order_by => ['a.id'],
        -page     => 1,
        -rows     => 2,
       });

    is ref $pager, 'Data::Page';
    is scalar @$rows, 2, 'total_entries';

    my $row = $rows->[0];
    isa_ok $row, 'Teng::Row';

    is $row->id, 1;
    is $row->name, 'perl2';

    my $row2 = $rows->[1];
    isa_ok $row2, 'Teng::Row';

    is $row2->id, 2;
    is $row2->name, 'python2';

    is $pager->current_page, 1;
    is $pager->first, 1;
    is $pager->last, 2;
};

subtest 'search original with join' => sub {
    my ($rows, $pager) = $db->search_by_sql_abstract_more_with_pager
      ({
        -where => {},,
        -columns => ['a.id', 'b.name'],
        -from => [-join =>
                  'mock_basic|a',
                  'a.id=b.mock_basic_id',
                  'mock_basic2|b',
                 ],
        -order_by => ['a.id'],
        -page     => 2,
        -rows     => 2,
       });

    is ref $pager, 'Data::Page';
    is scalar @$rows, 1, 'total_entries';

    my $row = $rows->[0];
    isa_ok $row, 'Teng::Row';

    is $row->id, 3;
    is $row->name, 'java2';

    is $pager->first, 3;
    is $pager->last, 3;
};

subtest 'search with join_and_hint_columns' => sub {
    my ($rows, $pager) = $db->search_by_sql_abstract_more_with_pager('mock_basic',{
    }, {
        -hint_columns => ['a.id'],
        -columns => ['a.id', 'b.name'],
        -from => [-join =>
                  'mock_basic|a',
                  'a.id=b.mock_basic_id',
                  'mock_basic2|b',
                 ],
        -order_by => ['a.id'],
        -page     => 1,
        -rows     => 2,
       });

    is ref $pager, 'Data::Page';
    is scalar @$rows, 2, 'total_entries';

    my $row = $rows->[0];
    isa_ok $row, 'Teng::Row';

    is $row->id, 1;
    is $row->name, 'perl2';

    my $row2 = $rows->[1];
    isa_ok $row2, 'Teng::Row';

    is $row2->id, 2;
    is $row2->name, 'python2';

    is $pager->current_page, 1;
    is $pager->first, 1;
    is $pager->last, 2;
};

subtest 'search original with join_and_hint_columns' => sub {
    my ($rows, $pager) = $db->search_by_sql_abstract_more_with_pager
      ({
        -where => {},
        -hint_columns => ['a.id'],
        -columns => ['a.id', 'b.name'],
        -from => [-join =>
                  'mock_basic|a',
                  'a.id=b.mock_basic_id',
                  'mock_basic2|b',
                 ],
        -order_by => ['a.id'],
        -page     => 2,
        -rows     => 2,
       });

    is ref $pager, 'Data::Page';
    is scalar @$rows, 1, 'total_entries';

    my $row = $rows->[0];
    isa_ok $row, 'Teng::Row';

    is $row->id, 3;
    is $row->name, 'java2';

    is $pager->first, 3;
    is $pager->last, 3;
};

done_testing;
