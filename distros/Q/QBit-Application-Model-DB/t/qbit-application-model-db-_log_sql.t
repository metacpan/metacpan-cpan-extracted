#!/usr/bin/perl

use qbit;

use lib::abs qw(../lib ./lib);

use Test::More tests => 4;

use TestAppDB;

my $app = TestAppDB->new();

$app->pre_run();

my $sql = $app->db->_log_sql('select * from table');

is($sql, q{select * from table}, 'Sql without params');

$sql = $app->db->_log_sql('select * from table', []);

is($sql, q{select * from table}, 'Sql with empty params');

$sql = $app->db->_log_sql('select * from table where id = ? or id = ?', [1, 2]);

is($sql, q{select * from table where id = '1' or id = '2'}, 'Params without ?');

$sql = $app->db->_log_sql('select * from table where title like ? or id = ?', ['what?', 2]);

is($sql, q{select * from table where title like 'what?' or id = '2'}, 'Params with ?');
