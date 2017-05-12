use strict;
use warnings;
use t::Utils;
use Mock::Basic;
use Test::More;
Mock::Basic->load_plugin('SearchBySQLAbstractMore');

my $dbh = t::Utils->setup_dbh;
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

subtest 'search' => sub {
    my $itr = $db->search_by_sql_abstract_more('mock_basic',{id => 1});
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';

    is $row->id, 1;
    is $row->name, 'perl';
};

subtest 'search in list context' => sub {
    my @rows = $db->search_by_sql_abstract_more('mock_basic',{id => 1});
    is scalar @rows, 1;
    isa_ok $rows[0], 'Teng::Row';

    is $rows[0]->id, 1;
    is $rows[0]->name, 'perl';
};

subtest 'search with join' => sub {
    my $itr = $db->search_by_sql_abstract_more('mock_basic', {
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
    my $itr = $db->search_by_sql_abstract_more({-where => {id => 1}, -from => 'mock_basic'});
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

subtest 'create_sql_by_sql_abstract_more' => sub {
    my $mksql = $db->sql_abstract_more_instance;
    {
        my @args = (
                    -where => {'a.name' => {'like' => 'p%'}},
                    -columns => ['a.id', 'b.name'],
                    -from => [-join =>
                              'mock_basic|a',
                              'a.id=b.mock_basic_id',
                              'mock_basic2|b',
                             ],
                    -order_by => ['a.id'],
                   );

        is_deeply([$db->create_sql_by_sql_abstract_more({@args})], [$mksql->select(@args)]);
    }
    {
        my @args = ('mock_basic',
                    {
                     'a.name' => {'like' => 'p%'},
                    },
                    {
                     -columns => ['a.id', 'b.name'],
                     -from => [-join =>
                               'mock_basic|a',
                               'a.id=b.mock_basic_id',
                               'mock_basic2|b',
                              ],
                     -order_by => ['a.id'],
                    });
        my ($table, $sql_args, $rows, $page) = Teng::Plugin::SearchBySQLAbstractMore::_arrange_args(@args);
        is_deeply([$db->create_sql_by_sql_abstract_more(@args)], [$mksql->select(%$sql_args)]);
    }
};

Teng::Plugin::SearchBySQLAbstractMore->replace_teng_search;

subtest 'search replaced' => sub {
    my $itr = $db->search('mock_basic',{id => 1});
    isa_ok $itr, 'Teng::Iterator';

    my $row = $itr->next;
    isa_ok $row, 'Teng::Row';

    is $row->id, 1;
    is $row->name, 'perl';
};

done_testing;
