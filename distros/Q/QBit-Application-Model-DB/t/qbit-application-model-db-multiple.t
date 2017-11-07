#!/usr/bin/perl

use qbit;

use lib::abs qw(../lib ./lib);

use Test::More tests => 2;

use TestAppDB;

my $app = TestAppDB->new();

$app->pre_run();

is_deeply(
    [map {$_->name} @{$app->db->table1->fields()}],
    ['field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9', 'field10'],
    'Check fields from db'
);

is_deeply([map {$_->name} @{$app->second_db->table1->fields()}], ['field1', 'field2'], 'Check fields from second_db');
