#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 10;

my $CLASS;
BEGIN {
    $CLASS = 'Module::Build::DBD::SQLite';
    use_ok $CLASS or die;
}

##############################################################################
# get_client()
is $CLASS->get_client, 'sqlite3', 'Client should be "sqlite3"';

##############################################################################
# get_db_and_command()
my $cmd = [
    'sqlite3',
    '-noheader',
    '-bail',
    '-column',
];

is_deeply [
    $CLASS->get_db_and_command('sqlite3', { dbname => 'foo_test' })
], [
    foo_test => $cmd
], 'get_db_and_command should work with super user, host, port';

##############################################################################
# get_db_option()
is_deeply [ $CLASS->get_db_option('heya') ], ['heya'],
    'get_db_option should work';

##############################################################################
# get_create_db_command()
is_deeply [ $CLASS->get_create_db_command( ['sqlite3'], 'myapp.db' ) ],
    [ $^X, '-e', 42 ],
    'get_create_db_command() should work';

##############################################################################
# get_drop_db_command()
is_deeply [ $CLASS->get_drop_db_command( ['sqlite3'], 'myapp.db' ) ],
    [ $^X, '-e', 'unlink shift', 'myapp.db' ],
    'get_drop_db_command() should work';

##############################################################################
# get_check_db_command()
is_deeply [ $CLASS->get_check_db_command( ['sqlite3'], 'myapp.db' ) ],
    [ $^X, '-l', '-e', "print 1 if -e shift", 'myapp.db' ],
    'get_check_db_command() should work';

##############################################################################
# get_execute_command()
is_deeply [ $CLASS->get_execute_command( ['sqlite3'], 'myapp.db', 'whatever' ) ],
    [ 'sqlite3', 'myapp.db', 'whatever' ],
    'get_execute_command() should work';

##############################################################################
# get_file_command()
is_deeply [ $CLASS->get_file_command( ['sqlite3'], 'myapp.db', 'whatever' ) ],
    [ 'sqlite3', 'myapp.db', '.read whatever' ],
    'get_file_command() should work';

##############################################################################
# get_meta_table_sql
is $CLASS->get_meta_table_sql('mymeta'), q{
        CREATE TABLE mymeta (
            label TEXT PRIMARY KEY,
            value INT  NOT NULL DEFAULT 0,
            note  TEXT NOT NULL
        );
    }, 'get_meta_table_sql() should work';

