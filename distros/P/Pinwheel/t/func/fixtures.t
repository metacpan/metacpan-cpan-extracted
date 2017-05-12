#! /usr/bin/env perl

use strict;
use warnings;

use POSIX qw(strftime);
use Test::More tests => 75;

use Pinwheel::Database;
use Pinwheel::Fixtures;


{
    package Pinwheel::Helpers::Fixtures;
    our @EXPORT_OK = qw(make_key);
    sub make_key { uc($_[0]) }
}


# Individual fixture files
{
    my $row;

    is(count_table_rows('one'), 1);
    is(count_table_rows('two'), 1);

    fixtures('one');
    is(count_table_rows('one'), 4, 'fixtures fills in "one" table');
    is(count_table_rows('two'), 0, 'calling fixtures clears other tables');
    is($Pinwheel::Fixtures::helpers, undef, 'helpers are not read unless erb is seen');

    fixtures('two');
    is(count_table_rows('one'), 4, 'further calls do not clear other tables');
    is(count_table_rows('two'), 4, 'fixtures fills in "two" table');

    foreach (1 ... 4) {
        $row = get_row('one', $_);
        is_deeply($row, {id => $_, text => "1.$_"});
        $row = get_row('two', $_);
        is_deeply($row, {id => $_, one_id => $_, text => "2.$_"});
    }
}


# Scenarios
{
    my $row;

    scenario('scenario1');
    is(count_table_rows('one'), 5);
    is(count_table_rows('two'), 4);
    foreach (1 ... 5) {
        $row = get_row('one', $_);
        is_deeply($row, {id => $_, text => "1.$_"});
    }
    foreach (1 ... 4) {
        $row = get_row('two', $_);
        is_deeply($row, {id => $_, one_id => $_, text => "2.$_"});
    }

    scenario('scenario1', root => 0);
    is(count_table_rows('one'), 1);
    is(count_table_rows('two'), 0);
    $row = get_row('one', 5);
    is_deeply($row, {id => 5, text => '1.5'});

    scenario('scenario1/plus2');
    is(count_table_rows('one'), 5);
    is(count_table_rows('two'), 5);
    foreach (1 ... 5) {
        $row = get_row('one', $_);
        is_deeply($row, {id => $_, text => "1.$_"});
        $row = get_row('two', $_);
        is_deeply($row, {id => $_, one_id => $_, text => "2.$_"});
    }

    scenario('scenario1/plus2', root => 1);
    is(count_table_rows('one'), 5);
    is(count_table_rows('two'), 5);
    foreach (1 ... 5) {
        $row = get_row('one', $_);
        is_deeply($row, {id => $_, text => "1.$_"});
        $row = get_row('two', $_);
        is_deeply($row, {id => $_, one_id => $_, text => "2.$_"});
    }

    scenario('scenario1/plus2', root => 0);
    is(count_table_rows('one'), 1);
    is(count_table_rows('two'), 1);
    $row = get_row('one', 5);
    is_deeply($row, {id => 5, text => '1.5'});
    $row = get_row('two', 5);
    is_deeply($row, {id => 5, one_id => 5, text => '2.5'});
}


# Auto-generated values
{
    my ($t1, $t2, $row, $id);

    $t1 = strftime('%Y-%m-%d %H:%M:%S', gmtime());
    fixtures('three');
    $t2 = strftime('%Y-%m-%d %H:%M:%S', gmtime());

    is(count_table_rows('three'), 4);

    $row = get_row('three', 1, 'anchor');
    $id = $row->{id};
    is($row->{non_numeric_id}, 'abcdefgh');
    is($row->{parent_id}, undef);
    cmp_ok($row->{created_on}, 'ge', $t1);
    cmp_ok($row->{created_on}, 'le', $t2);
    cmp_ok($row->{updated_at}, 'ge', $t1);
    cmp_ok($row->{updated_at}, 'le', $t2);

    $row = get_row('three', 2, 'anchor');
    is($row->{parent_id}, $id);
    cmp_ok($row->{created_on}, 'ge', $t1);
    cmp_ok($row->{created_on}, 'le', $t2);
    cmp_ok($row->{updated_at}, 'ge', $t1);
    cmp_ok($row->{updated_at}, 'le', $t2);

    $row = get_row('three', 3, 'anchor');
    is($row->{created_on}, '2007-01-01 10:20:30');
    is($row->{updated_at}, '2007-01-01 11:22:33');

    $row = get_row('three', 4);
    is($row->{parent_id}, $id);

    fixtures('four');
    is(count_table_rows('four'), 3);
}

# Embedded ERB
{
    my ($row);

    $Pinwheel::Fixtures::helpers->{make_key} = sub { uc($_[0]) };
    fixtures('four');
    $row = get_row('four', 'MARIO', 'name_key');
    is($row->{name}, 'Mario');

    $Pinwheel::Fixtures::helpers->{make_key} = sub { lc($_[0]) };
    fixtures('four');
    $row = get_row('four', 'mario', 'name_key');
    is($row->{name}, 'Mario');
}


sub count_table_rows
{
    my $table = shift;
    my $sth;

    $sth = Pinwheel::Database::prepare("SELECT COUNT(*) FROM $table");
    $sth->execute();
    return $sth->fetchall_arrayref()->[0][0];
}

sub get_row
{
    my ($table, $id, $column) = @_;
    my $sth;

    $column = 'id' if !$column;
    $sth = Pinwheel::Database::prepare("SELECT * FROM $table WHERE $column = ?");
    $sth->execute($id);
    return $sth->fetchall_arrayref({})->[0];
}


sub prepare_test_database
{
    Pinwheel::Database::set_connection(
        $ENV{'PINWHEEL_TEST_DB'} || 'dbi:SQLite:dbname=testdb.sqlite3',
        $ENV{'PINWHEEL_TEST_USER'} || '',
        $ENV{'PINWHEEL_TEST_PASS'} || ''
    );
    Pinwheel::Database::connect();
    my $testdb = q{
        DROP TABLE IF EXISTS `one`;
        CREATE TABLE `one` (
          `id` INT(11) NOT NULL,
          `text` VARCHAR(255) DEFAULT NULL,
          PRIMARY KEY (`id`)
        );

        DROP TABLE IF EXISTS `two`;
        CREATE TABLE `two` (
          `id` INT(11) NOT NULL,
          `one_id` INT(11) NOT NULL,
          `text` VARCHAR(255) DEFAULT NULL,
          PRIMARY KEY (`id`)
        );

        DROP TABLE IF EXISTS `three`;
        CREATE TABLE `three` (
          `id` INT(11) NOT NULL,
          `anchor` INT(11) DEFAULT NULL,
          `non_numeric_id` VARCHAR(8) DEFAULT NULL,
          `parent_id` INT(11) DEFAULT NULL,
          `updated_at` DATETIME NOT NULL,
          `created_on` DATETIME NOT NULL,
          PRIMARY KEY (`id`)
        );

        DROP TABLE IF EXISTS `four`;
        CREATE TABLE `four` (
          `four_id` INT(11) NOT NULL,
          `name` VARCHAR(255) NOT NULL,
          `name_key` VARCHAR(255) NOT NULL,
          PRIMARY KEY (`four_id`)
        );

        INSERT INTO `one` VALUES
            (1, '1.1');

        INSERT INTO `two` VALUES
            (1, 1, '2.1');
    };
    foreach (split(/\s*;\s*/, $testdb)) {
        Pinwheel::Database::do($_);
    }
}

BEGIN {
    prepare_test_database();
}
