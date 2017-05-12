use strict;
use warnings;
use utf8;
use Test::More;

use MySQL::Warmer;
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

$dbh->do(q[CREATE TABLE `test1` (
  `id` BIGINT unsigned NOT NULL auto_increment,
  `event_id` INTEGER NOT NULL,
  PRIMARY KEY (`id`, `event_id`)
)]);

$dbh->do(q[CREATE TABLE `test2` (
  `id` BIGINT unsigned NOT NULL auto_increment,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`, `created_at`)
)]);

$dbh->do(q[CREATE TABLE `test3` (
  `id` BIGINT unsigned PRIMARY KEY auto_increment,
  `name` VARCHAR(191) UNIQUE,
  `created_at` datetime NOT NULL
)]);

$dbh->do(q[CREATE TABLE `test4` (
  `id` BIGINT unsigned PRIMARY KEY auto_increment,
  `name` VARCHAR(191) NOT NULL,
  `created_at` datetime NOT NULL,
  INDEX `name_idx` (`name`)
)]);

$dbh->do(q[CREATE TABLE `test5` (
  `key` BIGINT unsigned PRIMARY KEY auto_increment
)]);

my $warmer = MySQL::Warmer->new(dbh => $dbh);

$warmer->run;

pass 'ok';

done_testing;
