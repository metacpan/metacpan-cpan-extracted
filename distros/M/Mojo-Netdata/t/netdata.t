use Test2::V0;
use Mojo::Netdata;
use Mojo::File qw(curfile);

subtest 'defaults' => sub {
  my $netdata = Mojo::Netdata->new;
  is $netdata->cache_dir,        '',                        'cache_dir';
  is $netdata->debug_flags,      '',                        'debug_flags';
  is $netdata->host_prefix,      '',                        'host_prefix';
  is $netdata->log_dir,          '',                        'log_dir';
  is $netdata->plugins_dir,      '',                        'plugins_dir';
  is $netdata->stock_config_dir, '/usr/lib/netdata/conf.d', 'stock_config_dir';
  is $netdata->update_every,     1,                         'update_every';
  is $netdata->user_config_dir,  '/etc/netdata',            'user_config_dir';
  is $netdata->web_dir,          '',                        'web_dir';
};

subtest 'env' => sub {
  local $ENV{NETDATA_CACHE_DIR}        = 5;
  local $ENV{NETDATA_DEBUG_FLAGS}      = 8;
  local $ENV{NETDATA_HOST_PREFIX}      = 7;
  local $ENV{NETDATA_LOG_DIR}          = 6;
  local $ENV{NETDATA_PLUGINS_DIR}      = 3;
  local $ENV{NETDATA_STOCK_CONFIG_DIR} = 2;
  local $ENV{NETDATA_UPDATE_EVERY}     = 9;
  local $ENV{NETDATA_USER_CONFIG_DIR}  = 1;
  local $ENV{NETDATA_WEB_DIR}          = 4;

  my $netdata = Mojo::Netdata->new;
  is $netdata->cache_dir,        5, 'cache_dir';
  is $netdata->debug_flags,      8, 'debug_flags';
  is $netdata->host_prefix,      7, 'host_prefix';
  is $netdata->log_dir,          6, 'log_dir';
  is $netdata->plugins_dir,      3, 'plugins_dir';
  is $netdata->stock_config_dir, 2, 'stock_config_dir';
  is $netdata->update_every,     9, 'update_every';
  is $netdata->user_config_dir,  1, 'user_config_dir';
  is $netdata->web_dir,          4, 'web_dir';
};

subtest 'mojo.conf.d' => sub {
  local $ENV{NETDATA_USER_CONFIG_DIR} = curfile->sibling('etc/netdata')->to_string;
  my $netdata = Mojo::Netdata->new;
  is(
    $netdata->config,
    {
      'main.conf.pl' => 1,
      'mojo.conf.pl' => 1,
      collectors     => [{
        collector    => 'Mojo::Netdata::Collector::HTTP',
        jobs         => ['https://example.com'],
        update_every => 30,
      }]
    },
    'read'
  );
};

subtest 'no config' => sub {
  local $ENV{NETDATA_USER_CONFIG_DIR} = curfile->sibling('etc/netdata-test-config')->to_string;
  my $netdata = Mojo::Netdata->new;
  is $netdata->config, {}, 'read';
};

done_testing;
