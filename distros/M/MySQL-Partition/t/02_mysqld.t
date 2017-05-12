use strict;
use warnings;
use utf8;
use Test::More;
use Test::mysqld;

my $mysqld = Test::mysqld->new(
    my_cnf => {
      'skip-networking' => '',
    }
) or plan skip_all => $Test::mysqld::errstr;

my @connect_info = ($mysqld->dsn(dbname => 'test'));
$connect_info[3] = {
    RaiseError          => 1,
    PrintError          => 0,
    ShowErrorStatement  => 1,
    AutoInactiveDestroy => 1,
    mysql_enable_utf8   => 1,
};
my $dbh = DBI->connect(@connect_info);

use MySQL::Partition;

subtest list => sub {
    $dbh->do(q[CREATE TABLE `test` (
      `id` BIGINT unsigned NOT NULL auto_increment,
      `event_id` INTEGER NOT NULL,
      PRIMARY KEY (`id`, `event_id`)
    )]);

    my $list_partition = MySQL::Partition->new(
        dbh        => $dbh,
        type       => 'list',
        table      => 'test',
        expression => 'event_id',
    );
    isa_ok $list_partition, 'MySQL::Partition::Type::List';

    ok !$list_partition->is_partitioned;
    $list_partition->create_partitions('p1' => 1);
    pass 'create_partitions ok';
    ok $list_partition->is_partitioned;
    ok $list_partition->has_partition('p1');
    my @partitions = $list_partition->retrieve_partitions;
    is_deeply \@partitions, ['p1'];

    subtest 'add_partitions' => sub {
        $list_partition->add_partitions('p2' => '2, 3');
        pass 'add_partitions ok';
        ok $list_partition->has_partition('p2');
        my @partitions = $list_partition->retrieve_partitions;
        is_deeply \@partitions, ['p1', 'p2'];
    };

    subtest 'truncate_partition' => sub {
        $dbh->do(q[INSERT INTO `test` (`event_id`) VALUES (1), (2)]);
        is_deeply $dbh->selectrow_arrayref(q[SELECT COUNT(*) FROM `test` WHERE `event_id` = 1]), [1];
        is_deeply $dbh->selectrow_arrayref(q[SELECT COUNT(*) FROM `test` WHERE `event_id` = 2]), [1];
        $list_partition->truncate_partitions('p1');
        pass 'truncate_partition ok';
        is_deeply $dbh->selectrow_arrayref(q[SELECT COUNT(*) FROM `test` WHERE `event_id` = 1]), [0];
        is_deeply $dbh->selectrow_arrayref(q[SELECT COUNT(*) FROM `test` WHERE `event_id` = 2]), [1];
        ok $list_partition->has_partition('p1');
        my @partitions = $list_partition->retrieve_partitions;
        is_deeply \@partitions, ['p1', 'p2'];
    };

    subtest 'drop_partition' => sub {
        $list_partition->drop_partitions('p1');
        pass 'drop_partition ok';
        ok !$list_partition->has_partition('p1');
        my @partitions = $list_partition->retrieve_partitions;
        is_deeply \@partitions, ['p2'];
    };
};

subtest 'range columns' => sub {
    $dbh->do(q[CREATE TABLE `test2` (
      `id` BIGINT unsigned NOT NULL auto_increment,
      `created_at` datetime NOT NULL,
      PRIMARY KEY (`id`, `created_at`)
    )]);

    my $range_partition = MySQL::Partition->new(
        dbh        => $dbh,
        type       => 'range columns',
        table      => 'test2',
        expression => 'created_at',
    );
    isa_ok $range_partition, 'MySQL::Partition::Type::Range';
    ok !$range_partition->is_partitioned;
    $range_partition->create_partitions('p20100101' => '2010-01-01');
    pass 'create_partitions ok';
    ok $range_partition->is_partitioned;
    ok $range_partition->has_partition('p20100101');
    my @partitions = $range_partition->retrieve_partitions;
    is_deeply \@partitions, ['p20100101'];

    subtest 'add_partitions' => sub {
        $range_partition->add_partitions(
            'p20110101' => '2011-01-01',
            'p20120101' => '2012-01-01',
        );
        ok $range_partition->has_partition('p20110101');
        ok $range_partition->has_partition('p20120101');
        my @partitions = $range_partition->retrieve_partitions;
        is_deeply \@partitions, ['p20100101', 'p20110101', 'p20120101'];
    };

    subtest 'truncate_partition' => sub {
        $dbh->do(q[INSERT INTO `test2` (`created_at`) VALUES
            ("2010-01-01 00:00:00"), ("2010-12-31 23:59:59"),
            ("2011-01-01 00:00:00"), ("2011-12-31 23:59:59")
        ]);
        is_deeply $dbh->selectrow_arrayref(q[
            SELECT COUNT(*) FROM `test2`
            WHERE `created_at` BETWEEN "2010-01-01 00:00:00" AND "2010-12-31 23:59:59"
        ]), [2];
        is_deeply $dbh->selectrow_arrayref(q[
            SELECT COUNT(*) FROM `test2`
            WHERE `created_at` BETWEEN "2011-01-01 00:00:00" AND "2011-12-31 23:59:59"
        ]), [2];
        $range_partition->truncate_partitions('p20110101');
        pass 'truncate_partition ok';
        is_deeply $dbh->selectrow_arrayref(q[
            SELECT COUNT(*) FROM `test2`
            WHERE `created_at` BETWEEN "2010-01-01 00:00:00" AND "2010-12-31 23:59:59"
        ]), [0];
        is_deeply $dbh->selectrow_arrayref(q[
            SELECT COUNT(*) FROM `test2`
            WHERE `created_at` BETWEEN "2011-01-01 00:00:00" AND "2011-12-31 23:59:59"
        ]), [2];
        ok $range_partition->has_partition('p20110101');
        my @partitions = $range_partition->retrieve_partitions;
        is_deeply \@partitions, ['p20100101', 'p20110101', 'p20120101'];
    };

    subtest 'drop_partition' => sub {
        $range_partition->drop_partitions('p20110101');
        pass 'drop_partition ok';
        ok !$range_partition->has_partition('p20110101');
        my @partitions = $range_partition->retrieve_partitions;
        is_deeply \@partitions, ['p20100101', 'p20120101'];
    };
};

subtest 'range and catch_all' => sub {
    $dbh->do(q[CREATE TABLE `test3` (
      `id` BIGINT unsigned NOT NULL auto_increment,
      `created_at` datetime NOT NULL,
      PRIMARY KEY (`id`, `created_at`)
    )]);

    my $range_partition = MySQL::Partition->new(
        dbh                      => $dbh,
        type                     => 'range',
        table                    => 'test3',
        expression               => 'TO_DAYS(created_at)',
        catch_all_partition_name => 'pmax',
    );
    $range_partition->create_partitions('p20100101' => q[TO_DAYS('2010-01-01')]);
    pass 'create_partitions ok';
    ok $range_partition->is_partitioned;
    ok $range_partition->has_partition('p20100101');
    ok $range_partition->has_partition('pmax');
    my @partitions = $range_partition->retrieve_partitions;
    is_deeply \@partitions, ['p20100101', 'pmax'];

    eval {
        $range_partition->add_partitions('p20110101' => q[TO_DAYS('2011-01-01')]);
    };
    ok $@;

    subtest 'reorganize_catch_all_partition' => sub {
        $range_partition->reorganize_catch_all_partition('p20110101' => q[TO_DAYS('2011-01-01')]);
        pass 'reorganize_catch_all_partition ok';
        ok $range_partition->has_partition('p20110101');
        my @partitions = $range_partition->retrieve_partitions;
        is_deeply \@partitions, ['p20100101', 'p20110101', 'pmax'];
    };
};

subtest 'dry-run' => sub {
    $dbh->do(q[CREATE TABLE `test4` (
      `id` BIGINT unsigned NOT NULL auto_increment,
      `event_id` INTEGER NOT NULL,
      PRIMARY KEY (`id`, `event_id`)
    )]);

    my $list_partition = MySQL::Partition->new(
        dbh        => $dbh,
        type       => 'list',
        table      => 'test4',
        expression => 'event_id',
        dry_run    => 1,
    );

    ok !$list_partition->is_partitioned;
    $list_partition->create_partitions('p1' => 1);
    pass 'create_partitions ok';
    ok !$list_partition->is_partitioned;
    ok !$list_partition->has_partition('p1');
    my @partitions = $list_partition->retrieve_partitions;
    is_deeply \@partitions, [];
};

subtest 'use handle' => sub {
    $dbh->do(q[CREATE TABLE `test5` (
      `id` BIGINT unsigned NOT NULL auto_increment,
      `event_id` INTEGER NOT NULL,
      PRIMARY KEY (`id`, `event_id`)
    )]);

    my $list_partition = MySQL::Partition->new(
        dbh        => $dbh,
        type       => 'list',
        table      => 'test5',
        expression => 'event_id',
    );
    my $handle = $list_partition->prepare_create_partitions(p1 => 1);
    ok !$list_partition->is_partitioned;
    $handle->execute;
    pass 'create_partitions ok';
    ok $list_partition->is_partitioned;
    my @partitions = $list_partition->retrieve_partitions;
    is_deeply \@partitions, ['p1'];

    subtest 'add_partitions' => sub {
        my $handle = $list_partition->prepare_add_partitions(p2 => {
            description => '2, 3',
            comment     => 'test',
        });
        is_deeply [$list_partition->retrieve_partitions], ['p1'];
        $handle->execute;
        pass 'add_partitions ok';
        is_deeply [$list_partition->retrieve_partitions], ['p1', 'p2'];
    };

    subtest 'truncate_partition' => sub {
        $dbh->do(q[INSERT INTO `test5` (`event_id`) VALUES (1)]);
        my $handle = $list_partition->prepare_truncate_partitions('p1');
        is_deeply $dbh->selectrow_arrayref(q[SELECT COUNT(*) FROM `test5` WHERE `event_id` = 1]), [1];
        $handle->execute;
        is_deeply $dbh->selectrow_arrayref(q[SELECT COUNT(*) FROM `test5` WHERE `event_id` = 1]), [0];
        pass 'truncate_partitions ok';
    };

    subtest 'drop_partition' => sub {
        my $handle = $list_partition->prepare_drop_partitions('p1');
        is_deeply [$list_partition->retrieve_partitions], ['p1', 'p2'];
        $handle->execute;
        pass 'drop_partitions ok';
        is_deeply [$list_partition->retrieve_partitions], ['p2'];
    };
};

done_testing;
