#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 13;

my $CLASS;
BEGIN {
    $CLASS = 'Module::Build::DBD::Pg';
    use_ok $CLASS or die;
}

##############################################################################
# get_client()
is $CLASS->get_client, 'psql', 'Client should be "psql"';

##############################################################################
# get_db_and_command()
my $cmd = [
    'psql',
    '--username' => 'foo',
    '--quiet',
    '--no-psqlrc',
    '--no-align',
    '--tuples-only',
    '--set' => 'ON_ERROR_ROLLBACK=1',
    '--set' => 'ON_ERROR_STOP=1',
];

is_deeply [
    $CLASS->get_db_and_command('psql', {
        dbname => 'foo_test',
        db_super_user => 'foo',
        host => 'localhost',
        port => 1234,
    })
], [
    foo_test => [
        @{ $cmd },
        '--host' => 'localhost',
        '--port' => 1234,
    ]
], 'get_db_and_command should work with super user, host, port';

$cmd->[2] = 'bar';
is_deeply [
    $CLASS->get_db_and_command('psql', {
        dbname => 'foo_test',
        username => 'bar'
    })
], [
    foo_test => $cmd
], 'get_db_and_command should work with username';

$cmd->[2] = 'baz';
is_deeply [
    $CLASS->get_db_and_command('psql', {
        dbname => 'you_test',
        username => 'baz'
    })
], [
    you_test => $cmd
], 'get_db_and_command should work with user and dbname';

unshift @{ $cmd }, $^X, '-e', '$ENV{PGPASSWORD} = shift; exec @ARGV', 'freddy';
is_deeply [
    $CLASS->get_db_and_command('psql', {
        dbname => 'you_test',
        db_super_user => 'baz',
        db_super_pass => 'freddy'
    })
], [
    you_test => $cmd
], 'get_db_and_command should work with db_super_pass';

##############################################################################
# get_db_option()
is_deeply [ $CLASS->get_db_option('heya') ], ['--dbname', 'heya'],
    'get_db_option should work';

##############################################################################
# get_create_db_command()
is_deeply [ $CLASS->get_create_db_command( ['psql'], 'myapp' ) ],
    [ 'psql', '--dbname', 'template1', '--command', q{CREATE DATABASE "myapp"} ],
    'get_create_db_command() should work';

##############################################################################
# get_drop_db_command()
is_deeply [ $CLASS->get_drop_db_command( ['psql'], 'myapp' ) ],
    [ 'psql', '--dbname', 'template1', '--command', q{DROP DATABASE IF EXISTS "myapp"} ],
    'get_drop_db_command() should work';

##############################################################################
# get_check_db_command()
is_deeply [ $CLASS->get_check_db_command( ['psql'], 'myapp' ) ],
    [ 'psql', '--dbname', 'template1', '--command', q{
        SELECT 1
          FROM pg_catalog.pg_database
         WHERE datname = 'myapp';
    } ],
    'get_check_db_command() should work';

##############################################################################
# get_execute_command()
is_deeply [ $CLASS->get_execute_command( ['psql'], 'myapp', 'whatever' ) ],
    [ 'psql', '--dbname', 'myapp', '--command', 'whatever' ],
    'get_execute_command() should work';

##############################################################################
# get_file_command()
is_deeply [ $CLASS->get_file_command( ['psql'], 'myapp', 'whatever' ) ],
    [ 'psql', '--dbname', 'myapp', '--file', 'whatever' ],
    'get_file_command() should work';

##############################################################################
# get_meta_table_sql
is $CLASS->get_meta_table_sql('mymeta'), q{
        SET client_min_messages=warning;
        CREATE TABLE mymeta (
            label TEXT PRIMARY KEY,
            value INT  NOT NULL DEFAULT 0,
            note  TEXT NOT NULL
        );
        RESET client_min_messages;
    }, 'get_meta_table_sql() should work';

