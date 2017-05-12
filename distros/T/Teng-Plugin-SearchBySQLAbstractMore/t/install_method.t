use strict;
use warnings;
use t::Utils;
use Mock::Basic;
use Test::More;
Mock::Basic->load_plugin('SearchBySQLAbstractMore');

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});

$db->install_sql_abstract_more(pager => 'Pager');

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

subtest 'search' => sub {
    my $itr = $db->search('mock_basic',{id => 1});
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';

    is $row->id, 1;
    is $row->name, 'perl';
};

subtest 'search with join' => sub {
    my $itr = $db->search('mock_basic', {
        'a.name' => {'like' => 'p%'},
    }, {
        -columns => ['a.id', 'b.name'],
        -from => [-join =>
                  'mock_basic|a',
                  'a.id=b.mock_basic_id',
                  'mock_basic2|b',
                 ],
        -order_by => ['a.id'],
       });

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';

    is $row->id, 1;
    is $row->name, 'perl2';

    my $row2 = $itr->next;

    isa_ok $row2, 'Teng::Row';

    is $row2->id, 2;
    is $row2->name, 'python2';
};

subtest 'search original' => sub {
    my $itr = $db->search({-where => {id => 1}, -from => 'mock_basic'});
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';

    is $row->id, 1;
    is $row->name, 'perl';
};

subtest 'search original with join' => sub {
    my $itr = $db->search_by_sql_abstract_more
      ({
        -where => {'a.name' => {'like' => 'p%'}},
        -columns => ['a.id', 'b.name'],
        -from => [-join =>
                  'mock_basic|a',
                  'a.id=b.mock_basic_id',
                  'mock_basic2|b',
                 ],
        -order_by => ['a.id'],
       });

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';

    is $row->id, 1;
    is $row->name, 'perl2';

    my $row2 = $itr->next;

    isa_ok $row2, 'Teng::Row';

    is $row2->id, 2;
    is $row2->name, 'python2';
};

subtest 'search with join' => sub {
    my ($rows, $pager) = $db->search_with_pager('mock_basic',{
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

    is ref $pager, 'Data::Page::NoTotalEntries';
    is scalar @$rows, 2;

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
    my ($rows, $pager) = $db->search_with_pager
      ({
        -where => {},,
        -columns => ['a.id', 'b.name'],
        -from => [-join =>
                  'mock_basic | a',
                  'a.id=b.mock_basic_id',
                  'mock_basic2 | b',
                 ],
        -order_by => ['a.id'],
        -page     => 2,
        -rows     => 2,
       });

    is ref $pager, 'Data::Page::NoTotalEntries';
    is scalar @$rows, 1;

    my $row = $rows->[0];
    isa_ok $row, 'Teng::Row';

    is $row->id, 3;
    is $row->name, 'java2';

    is $pager->first, 3;
    is $pager->last, 3;
};


done_testing;
