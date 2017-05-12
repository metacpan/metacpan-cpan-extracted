#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 13;

my $CLASS;
BEGIN {
    $CLASS = 'Module::Build::DBD::mysql';
    use_ok $CLASS or die;
}

##############################################################################
# get_client()
is $CLASS->get_client, 'mysql', 'Client should be "mysql"';

##############################################################################
# get_db_and_command()
my $cmd = [
    'mysql',
    '--user' => 'foo',
    '--skip-pager',
    '--silent',
    '--skip-column-names',
    '--skip-line-numbers',
];

is_deeply [
    $CLASS->get_db_and_command('mysql', {
        database => 'foo_test',
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
    $CLASS->get_db_and_command('mysql', {
        database => 'foo_test',
        username => 'bar'
    })
], [
    foo_test => $cmd
], 'get_db_and_command should work with username';

$cmd->[2] = 'baz';
is_deeply [
    $CLASS->get_db_and_command('mysql', {
        database => 'you_test',
        username => 'baz'
    })
], [
    you_test => $cmd
], 'get_db_and_command should work with user and database';

push @{$cmd}, '--password=freddy';
is_deeply [
    $CLASS->get_db_and_command('mysql', {
        database => 'you_test',
        db_super_user => 'baz',
        db_super_pass => 'freddy'
    })
], [
    you_test => $cmd
], 'get_db_and_command should work with db_super_pass';

##############################################################################
# get_db_option()
is_deeply [ $CLASS->get_db_option('heya') ], ['--database', 'heya'],
    'get_db_option should work';

##############################################################################
# get_create_db_command()
is_deeply [ $CLASS->get_create_db_command( ['mysql'], 'myapp' ) ],
    [ 'mysql', '--execute', q{CREATE DATABASE "myapp"} ],
    'get_create_db_command() should work';

##############################################################################
# get_drop_db_command()
is_deeply [ $CLASS->get_drop_db_command( ['mysql'], 'myapp' ) ],
    [ 'mysql', '--execute', q{DROP DATABASE IF EXISTS "myapp"} ],
    'get_drop_db_command() should work';

##############################################################################
# get_check_db_command()
is_deeply [ $CLASS->get_check_db_command( ['mysql'], 'myapp' ) ],
    [ 'mysql', '--execute', q{
        SELECT 1
          FROM information_schema.schemata
         WHERE schema_name = 'myapp';
    } ],
    'get_check_db_command() should work';

##############################################################################
# get_execute_command()
is_deeply [ $CLASS->get_execute_command( ['mysql'], 'myapp', 'whatever' ) ],
    [ 'mysql', '--database', 'myapp', '--execute', 'whatever' ],
    'get_execute_command() should work';

##############################################################################
# get_file_command()
is_deeply [ $CLASS->get_file_command( ['mysql'], 'myapp', 'whatever' ) ],
    [ 'mysql', '--database', 'myapp', '--execute', 'source whatever' ],
    'get_file_command() should work';

##############################################################################
# get_meta_table_sql
is $CLASS->get_meta_table_sql('mymeta'), q{
        CREATE TABLE mymeta (
            label VARCHAR(255) PRIMARY KEY,
            value INT  NOT NULL DEFAULT 0,
            note  TEXT NOT NULL
        );
    }, 'get_meta_table_sql() should work';

