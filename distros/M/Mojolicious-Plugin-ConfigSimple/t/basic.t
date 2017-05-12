use lib qw( lib local/lib/perl5 );
use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Test::Exception;
use Data::Dumper;

my ($config,$cfg);
my $ini = 't/conf.d/config.ini';

throws_ok 
  { ($config, $cfg) = plugin ( 'ConfigSimple' => { config_file => [ $ini ], } ) } 
  qr/config_file key requires a SCALAR/, 
  'config_file key properly sanity checked';

throws_ok 
  { ($config, $cfg) = plugin ( 'ConfigSimple' => { config_files => $ini, } ) } 
  qr/config_files key requires an ARRAYREF/, 
  'config_files key properly sanity checked';

$config = plugin ( 'ConfigSimple' => { config_files => [ $ini ], } );
is_deeply($config, &cfg_vars,
    'registering the plugin as a scalar returns expected data structure' );

($config, $cfg) = plugin ( 'ConfigSimple' => { config_files => [ $ini ], } );
is_deeply($config, &cfg_vars,
    'registering the plugin as an array also returns an idiomatic config data structure' );

isa_ok( $cfg, 'Config::Simple' );
can_ok( $cfg, 'param' );
can_ok( $cfg, 'vars' );
can_ok( $cfg, 'get_block' );

is_deeply(\%{$cfg->vars},
    &cfg_vars,
    '->vars returns expected data structure' );

is_deeply(\%{$cfg->get_block('db')},
    &cfg_get_block,
    '->get_block returns expected data structure' );

is_deeply( { map{ $_ => 1 }@{ Config::Simple::Extended::get_stanzas( $cfg ) } },
    &cfg_get_stanzas,
    'Config::Simple::Extended::get_stanzas returns expected data structure' );

is($cfg->param("default.foo"),'bar', '->param() method works too.');

note &Mojolicious::Plugin::ConfigSimple::version;

done_testing();

sub cfg_get_stanzas {
  return { db => 1, default => 1 };
}

sub cfg_get_block {
  return {
    'db_name' => 'foo_db',
    'db_user' => 'foo_user',
    'db_pw' => 'secret',
    'db_ssl' => '1',
    'db_host' => '127.0.0.1',
    'db_engine' => 'Pg'
  }; 
}

sub cfg_vars {
  my $expected = {
    'db.db_engine' => 'Pg',
    'default.foo' => 'bar',
    'db.db_host' => '127.0.0.1',
    'db.db_ssl' => '1',
    'db.db_name' => 'foo_db',
    'db.db_pw' => 'secret',
    'db.db_user' => 'foo_user'
  };
  return $expected;
}

