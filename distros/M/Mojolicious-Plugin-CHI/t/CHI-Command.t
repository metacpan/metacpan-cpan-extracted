#!/usr/bin/env perl
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Data::Dumper;
use Test::Output qw/:stdout :stderr :functions/;
use File::Temp qw/:POSIX tempdir/;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::CHI';

my $t = Test::Mojo->new;
my $app = $t->app;

my $hash1 = {};
my $hash2 = {};

$app->plugin(Config => {
  default => {
    CHI => {
      first => {
        driver => 'Memory',
	datastore => $hash1
      },
      MySecondCache => {
        driver => 'Memory',
	datastore => $hash2
      }
    }
  }
});

$app->plugin('CHI');

my $cmds = $app->commands;

ok(grep/::CHI/, @{$cmds->namespaces}, 'Namespace is set');
is_deeply(
  $cmds->namespaces,
  [qw/Mojolicious::Command Mojolicious::Plugin::CHI/],
  'Namespace is set'
);

stdout_like(
  sub {
    local $ENV{HARNESS_ACTIVE} = 0;
    $cmds->run;
  },
  qr/chi.+?Interact with CHI caches/,
  'Command established'
);


{
  no warnings;
  $Time::Duration::MILLISECOND = 1;
};

use_ok('Mojolicious::Plugin::CHI::chi');

my $chi = Mojolicious::Plugin::CHI::chi->new;
$chi->app($app);

is($chi->description, "Interact with CHI caches", 'Description line');

stdout_like(
  sub { $chi->run },
  qr/perl app\.pl chi clear mycache/,
  'Show option list'
);

my $usage = $chi->usage;

stdout_is(
  sub { $chi->run },
  $usage,
  'Show option list'
);

stdout_like(
  sub { $chi->run('list') },
  qr/first\s+Memory\s+MySecondCache\s+Memory/,
  'Show driver list'
);

my $path = tempdir(CLEANUP => 1);
$app->plugin(CHI => {
  MyFlatFile => {
    driver => 'File',
    root_dir => $path,
    # This may be a mysterious CHI bug
    max_key_length => 200
  }
});

$cmds = $app->commands;
is_deeply(
  $cmds->namespaces,
  [qw/Mojolicious::Command Mojolicious::Plugin::CHI/],
  'Namespace is set only once'
);


stdout_like(
  sub { $chi->run('list') },
  qr/first\s+Memory\s+MyFlatFile\s+File\s+MySecondCache\s+Memory/,
  'Show driver list'
);

my $flat_file = $app->chi('MyFlatFile');
ok($flat_file->set(key_1 => 'value_1', { expires_in => '5m' }), 'Set key');
is($flat_file->get('key_1'), 'value_1', 'Get key');
ok($flat_file->set(key_2 => 'value_2' => { expires_in => 0.1 }), 'Set key');

select(undef, undef, undef, 0.2);

ok(!$flat_file->get('key_2'), 'Get key impossible');
ok($flat_file->get_object('key_2')->is_expired, 'Key is expired');

stdout_is(
  sub { $chi->run('purge', 'Unknown') },
  "Unknown cache handle \"Unknown\".\n\n",
  'Purge cache'
);

stdout_is(
  sub { $chi->run('purge', 'MyFlatFile') },
  "Cache \"MyFlatFile\" was purged.\n\n",
  'Purge cache'
);

ok(!$flat_file->get_object('key_2'), 'Key is removed');
is($flat_file->get('key_1'), 'value_1', 'Get key');

stdout_is(
  sub { $chi->run('clear', 'Unknown') },
  "Unknown cache handle \"Unknown\".\n\n",
  'Clear cache'
);

stdout_is(
  sub { $chi->run('clear', 'MyFlatFile') },
  "Cache \"MyFlatFile\" was cleared.\n\n",
  'Clear cache'
);

ok(!$flat_file->get_object('key_1'), 'Key is removed');

ok($flat_file->set(key_3 => 'value_3'), 'Set key');
ok($flat_file->set(key_4 => 'value_4'), 'Set key');
is($flat_file->get('key_3'), 'value_3', 'Get key');
is($flat_file->get('key_4'), 'value_4', 'Get key');

stdout_is(
  sub { $chi->run('remove', 'Unknown', 'key') },
  "Unknown cache handle \"Unknown\".\n\n",
  'Remove key'
);

stdout_is(
  sub { $chi->run('remove', 'MyFlatFile', 'key_3') },
  "Key \"key_3\" from cache \"MyFlatFile\" was removed.\n\n",
  'Remove key'
);
ok(!$flat_file->get('key_3'), 'Get key');

is($flat_file->get('key_4'), 'value_4', 'Get key');

stdout_is(
  sub { $chi->run('expire', 'Unknown', 'key') },
  "Unknown cache handle \"Unknown\".\n\n",
  'Expire key'
);

stdout_is(
  sub { $chi->run('expire', 'MyFlatFile', 'key_4') },
  "Key \"key_4\" from cache \"MyFlatFile\" was expired.\n\n",
  'Expire key'
);

ok(!$flat_file->get('key_4'), 'Unable to get key');

ok($flat_file->get_object('key_4')->is_expired, 'Key is expired');

stdout_is(
  sub { $chi->run('remove', 'MyFlatFile', 'key_3') },
  "Unable to remove key \"key_3\" from cache \"MyFlatFile\".\n\n",
  'Expire key'
);

# Again with default

$path = tempdir(CLEANUP => 1);
$app->plugin(CHI => {
  default => {
    driver => 'File',
    root_dir => $path
  }
});

my $cache = $app->chi;
ok($cache->set(key_1 => 'value_1', { expires_in => '5m' }), 'Set key');
is($cache->get('key_1'), 'value_1', 'Get key');
ok($cache->set(key_2 => 'value_2' => { expires_in => 0.1 }), 'Set key');

select(undef, undef, undef, 0.2);

ok(!$cache->get('key_2'), 'Get key impossible');
ok($cache->get_object('key_2')->is_expired, 'Key is expired');

stdout_is(
  sub { $chi->run('purge') },
  qq{Cache "default" was purged.\n\n},
  'Purge cache'
);

ok(!$cache->get_object('key_2'), 'Key is removed');
is($cache->get('key_1'), 'value_1', 'Get key');

stdout_is(
  sub { $chi->run('clear') },
  qq{Cache "default" was cleared.\n\n},
  'Clear cache'
);

ok(!$cache->get_object('key_1'), 'Key is removed');

ok($cache->set(key_3 => 'value_3'), 'Set key');
ok($cache->set(key_4 => 'value_4'), 'Set key');
is($cache->get('key_3'), 'value_3', 'Get key');
is($cache->get('key_4'), 'value_4', 'Get key');

stdout_is(
  sub { $chi->run('remove', 'key_3') },
  qq{Key "key_3" from cache "default" was removed.\n\n},
  'Remove key'
);
ok(!$cache->get('key_3'), 'Get key');

is($cache->get('key_4'), 'value_4', 'Get key');

stdout_is(
  sub { $chi->run('expire', 'key_4') },
  qq{Key "key_4" from cache "default" was expired.\n\n},
  'Expire key'
);

ok(!$cache->get('key_4'), 'Unable to get key');

ok($cache->get_object('key_4')->is_expired, 'Key is expired');

stdout_is(
  sub { $chi->run('remove', 'key_3') },
  qq{Unable to remove key "key_3" from cache "default".\n\n},
  'Expire key'
);

done_testing;
