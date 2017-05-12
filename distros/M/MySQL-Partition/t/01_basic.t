use strict;
use warnings;
use utf8;
use Test::More 0.98;

use MySQL::Partition;

subtest list => sub {
    my $list_partition = MySQL::Partition->new(
        dbh        => 'dummy',
        type       => 'list',
        table      => 'test',
        expression => 'event_id',
    );
    isa_ok $list_partition, 'MySQL::Partition::Type::List';

    is $list_partition->_build_create_partitions_sql('p1' => 1),
       'ALTER TABLE test PARTITION BY LIST (event_id) (PARTITION p1 VALUES IN (1))';
    is $list_partition->_build_add_partitions_sql('p2' => '2, 3'),
       'ALTER TABLE test ADD PARTITION (PARTITION p2 VALUES IN (2, 3))';
    is $list_partition->_build_drop_partitions_sql('p1'),
       'ALTER TABLE test DROP PARTITION p1';
    is $list_partition->_build_truncate_partitions_sql('p1'),
       'ALTER TABLE test TRUNCATE PARTITION p1';
};

subtest range => sub {
    my $range_partition = MySQL::Partition->new(
        dbh        => 'dummy',
        type       => 'range columns',
        table      => 'test2',
        expression => 'created_at',
    );
    isa_ok $range_partition, 'MySQL::Partition::Type::Range';

    is $range_partition->_build_create_partitions_sql('p20100101' => '2010-01-01'),
       q[ALTER TABLE test2 PARTITION BY RANGE COLUMNS (created_at) (PARTITION p20100101 VALUES LESS THAN ('2010-01-01'))];
    is $range_partition->_build_add_partitions_sql(
        'p20110101' => '2011-01-01',
        'p20120101' => '2012-01-01',
    ), q[ALTER TABLE test2 ADD PARTITION (PARTITION p20110101 VALUES LESS THAN ('2011-01-01'), PARTITION p20120101 VALUES LESS THAN ('2012-01-01'))];
};

subtest 'range and catch_all' => sub {
    my $range_partition = MySQL::Partition->new(
        dbh                      => 'dummy',
        type                     => 'range',
        table                    => 'test3',
        expression               => 'TO_DAYS(created_at)',
        catch_all_partition_name => 'pmax',
    );

    is $range_partition->_build_create_partitions_sql('p20100101' => q[TO_DAYS('2010-01-01')]),
       q[ALTER TABLE test3 PARTITION BY RANGE ].
       q[(TO_DAYS(created_at)) (PARTITION p20100101 VALUES LESS THAN (TO_DAYS('2010-01-01')), PARTITION pmax VALUES LESS THAN (MAXVALUE))];

    is $range_partition->_build_add_catch_all_partition_sql,
       'ALTER TABLE test3 ADD PARTITION (PARTITION pmax VALUES LESS THAN (MAXVALUE))';

    is $range_partition->_build_reorganize_catch_all_partition_sql('p20110101' => q[TO_DAYS('2011-01-01')]),
       q[ALTER TABLE test3 REORGANIZE PARTITION pmax INTO (PARTITION p20110101 VALUES LESS THAN (TO_DAYS('2011-01-01')), ].
       q[PARTITION pmax VALUES LESS THAN (MAXVALUE))];
};

subtest 'range _build_partition_part' => sub {
    my $range_partition = MySQL::Partition->new(
        dbh                      => 'dummy',
        type                     => 'range',
        table                    => 'test3',
        expression               => 'TO_DAYS(created_at)',
        catch_all_partition_name => 'pmax',
    );
    is $range_partition->_build_partition_part(p111 => {
        comment     => 'test111',
        description => '111',
    }), q[PARTITION p111 VALUES LESS THAN (111) COMMENT = 'test111'];
};

subtest 'list _build_partition_part' => sub {
    my $range_partition = MySQL::Partition->new(
        dbh                      => 'dummy',
        type                     => 'list',
        table                    => 'test3',
        expression               => 'event_id',
        catch_all_partition_name => 'pmax',
    );
    is $range_partition->_build_partition_part(p1122 => {
        comment     => 'test1122',
        description => '1122',
    }), q[PARTITION p1122 VALUES IN (1122) COMMENT = 'test1122'];
};

done_testing;
