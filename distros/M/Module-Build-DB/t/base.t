#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 16;
use File::Spec::Functions qw(catdir catfile updir);

my $CLASS;
BEGIN {
    $CLASS = 'Module::Build::DB';
    use_ok $CLASS or die;
}

my $dir = catdir qw(t lib pgtest);
chdir $dir or die "Can't chdir to $dir: $!\n";

ok my $mb = $CLASS->new( module_name => 'Foo', quiet => 1 ),
    'Create M::B::DB object';

# Check default property values.
is $mb->context,        'test',     'context should be "test"';
is $mb->replace_config, undef,      'replac_config should be undef';
is $mb->db_config_key,  'dbi',      'dbi_config_key should be "dbi"';
is $mb->db_client,      undef,      'db_client should be undef';
ok !$mb->drop_db,                   'drop_db should be false';
is $mb->db_super_user,  undef,      'db_super_user should be undef';
is $mb->db_super_pass,  undef,      'db_super_pass should be undef';
is_deeply $mb->test_env, {},        'test_env should be {}';
is $mb->meta_table,     'metadata', 'meta_table should be "metadata"';

# Test config.
require Config::Any::YAML;
SKIP: {
    skip 'YAML config not supported', 2
        unless Config::Any::YAML->is_supported;
    is $mb->cx_config_file, catfile(qw(conf test.yml)),
        'cx_config_file should be "conf/test.yml"';
    is_deeply $mb->cx_config, { dbi => {
        dsn      => 'dbi:Pg:dbname=foo_test',
        username => 'postgres',
        password => ''
    }}, 'cx_config should be correct';
}

# Test etc and JSON.
$dir = catdir updir, 'mytest';
chdir $dir or die "Can't chdir to $dir: $!\n";
ok $mb = $CLASS->new( module_name => 'Foo', quiet => 1 ),
    'Create another M::B::DB object';
require Config::Any::JSON;
SKIP: {
    skip 'JSON config not supported', 2
        unless Config::Any::JSON->is_supported;
    is $mb->cx_config_file, catfile(qw(etc test.json)),
        'cx_config_file should be "etc/test.json"';
    is_deeply $mb->cx_config, { dbi => {
        dsn      => 'dbi:mysql:database=foo_test',
        username => 'root',
        password => ''
    }}, 'cx_config should be correct';
}
