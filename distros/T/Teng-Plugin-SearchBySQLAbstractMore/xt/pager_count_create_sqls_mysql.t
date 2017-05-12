use xt::Utils::mysql;
use Mock::Basic;
use Test::More;
Mock::Basic->load_plugin('SearchBySQLAbstractMore::Pager::Count');

my $dbh = t::Utils->setup_dbh;
my $db = Mock::Basic->new({dbh => $dbh});
$db->setup_test_db;

my $mksqls = \&Teng::Plugin::SearchBySQLAbstractMore::Pager::Count::_create_sqls;

subtest "search",
    sub {
     my ($sql, $binds, $count_sql, $count_binds)
     = $mksqls->($db,
                 {-columns  => [qw/user_id name/],
                  -limit    => 20,
                  -offset   => 1,
                  -where    => { user_id => { '>', 10 } },
                  -from     => 'users',
                 }
                );

     is _regularize($sql), 'select user_id, name from users where ( user_id > ? ) limit ? offset ?';
     is_deeply $binds, [10, 20, 1];
     is _regularize($count_sql), 'select count(*) from users where ( user_id > ? )';
     is_deeply $count_binds, [10];
    };

subtest "search_with_group_by",
    sub {
     my ($sql, $binds, $count_sql, $count_binds)
     = $mksqls->($db,
                 {-columns  => [qw/user_id count(*) date(clicked_datetime)/],
                  -group_by => [qw/user_id date(clicked_datetime)/],
                  -limit    => 20,
                  -offset   => 1,
                  -where    => { user_id => { '>', 10 } },
                  -from     => 'clicks',
                 }
                );

     is _regularize($sql), 'select user_id, count(*), date(clicked_datetime) from clicks where ( user_id > ? ) group by user_id, date(clicked_datetime) limit ? offset ?';
     is_deeply $binds, [10, 20, 1];
     is _regularize($count_sql), 'select count(*) as cnt from (select user_id, count(*), date(clicked_datetime) from clicks where ( user_id > ? ) group by user_id, date(clicked_datetime) order by null) as total_count';
     is_deeply $count_binds, [10];
    };

subtest "search_group_by_and_having",
    sub {
     my ($sql, $binds, $count_sql, $count_binds)
     = $mksqls->($db,
                 {
                  -from  => 'clicks',
                  -columns      => [qw/user_id count(*) date(clicked_datetime)/],
                  -group_by     => [qw/user_id date(clicked_datetime)/],
                  -having   => [{'count(*)' => {'>', 15}}],
                  -limit    => 20,
                  -offset   => 1,
                 }
                );
     is _regularize($sql), 'select user_id, count(*), date(clicked_datetime) from clicks group by user_id, date(clicked_datetime) having ( count(*) > ? ) limit ? offset ?';
     is_deeply $binds, [15, 20, 1];
     is _regularize($count_sql), 'select count(*) as cnt from (select user_id, count(*), date(clicked_datetime) from clicks group by user_id, date(clicked_datetime) having ( count(*) > ? ) order by null) as total_count';
     is_deeply $count_binds, [15];
    };

subtest "search_with_group_by_and_hint_columns",
    sub {
     my ($sql, $binds, $count_sql, $count_binds)
     = $mksqls->($db,
                 {
                  -from  => 'clicks',
                  -columns      => [qw/user_id count(*) date(clicked_datetime)/],
                  -group_by     => [qw/user_id date(clicked_datetime)/],
                  -hint_columns => [qw/user_id/],
                  -limit    => 20,
                  -offset   => 1,
                 }
                );
     is _regularize($sql), 'select user_id, count(*), date(clicked_datetime) from clicks group by user_id, date(clicked_datetime) limit ? offset ?';
     is_deeply $binds, [20, 1];
     is _regularize($count_sql), 'select count(*) as cnt from (select user_id from clicks group by user_id, date(clicked_datetime) order by null) as total_count';
     is_deeply $count_binds, [];
    };

subtest "search_group_by_and_hint_columns_and_having",
    sub {
     my ($sql, $binds, $count_sql, $count_binds)
     = $mksqls->($db,
                 {
                  -from  => 'clicks',
                  -columns      => [qw/user_id count(*) date(clicked_datetime)/],
                  -group_by     => [qw/user_id date(clicked_datetime)/],
                  -hint_columns => [qw/count(*)/],
                  -having   => [{'count(*)' => {'>', 15}}],
                  -limit    => 20,
                  -offset   => 1,
                 }
                );
     is _regularize($sql), 'select user_id, count(*), date(clicked_datetime) from clicks group by user_id, date(clicked_datetime) having ( count(*) > ? ) limit ? offset ?';
     is_deeply $binds, [15, 20, 1];
     is _regularize($count_sql), 'select count(*) as cnt from (select count(*) from clicks group by user_id, date(clicked_datetime) having ( count(*) > ? ) order by null) as total_count';
     is_deeply $count_binds, [15];
    };

done_testing();

sub _regularize {
    my ($sql) = @_;
    $sql =~s{\s+}{ }g;
    lc $sql;
}
