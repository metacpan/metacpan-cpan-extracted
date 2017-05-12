#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use File::Find;
use File::Spec::Functions qw(catdir splitdir);

my $CLASS;
my @drivers;
BEGIN {
    $CLASS   = 'Module::Build::DB';
    my $dir  = catdir qw(lib Module Build DBD);
    my $qdir = quotemeta $dir;
    find {
        no_chdir => 1,
        wanted   => sub {
            s/[.]pm$// or return;
            s{^$qdir/?}{};
            push @drivers, $CLASS . 'D::' . join( '::', splitdir $_);
        }
    }, $dir;
}

plan tests => (@drivers * 2) + 2;

# Test the main class.
use_ok $CLASS or die;
can_ok $CLASS, qw(
    context
    cx_config
    cx_config_file
    replace_config
    db_config_key
    db_client
    drop_db
    db_super_user
    db_super_pass
    test_env
    meta_table
    ACTION_test
    run_tap_harness
    ACTION_config_data
    ACTION_db
    cx_config
    db_cmd
    create_meta_table
    upgrade_db
    _probe
);

# Test the drivers.
for my $driver (@drivers) {
    use_ok $driver;
    can_ok $driver, qw(
        get_client
        get_db_and_command
        get_db_option
        get_create_db_command
        get_drop_db_command
        get_check_db_command
        get_execute_command
        get_file_command
        get_meta_table_sql
    );
}
