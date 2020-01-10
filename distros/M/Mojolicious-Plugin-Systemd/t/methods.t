use Mojo::Base -strict;
use Test::More;
use Mojolicious::Plugin::Systemd;

$ENV{$_} = $_ for qw(FOO BAR BAZ);
my $p = Mojolicious::Plugin::Systemd->new;

note 'set, unset';
$p->_set_environment(FOO => 42);
is $ENV{FOO}, 42, 'set FOO=42';

$p->_set_environment(FOO => q("24"));
is $ENV{FOO}, 24, 'set FOO=24';

$ENV{BAR} = 'BAR';
$p->_unset_multiple_environment(q( FOO   "BAR"  ));
is_deeply [@ENV{qw(FOO BAR BAZ)}], [undef, undef, 'BAZ'], 'unset';

$p->_set_multiple_environment(
  q("FOO=word1 word2" BAR=word3 "BAZ=$word 5 6" FOO="w=1"));
is_deeply [@ENV{qw(FOO BAR BAZ)}], ['w=1', 'word3', '$word 5 6'],
  'set multiple';

note '_config_from_env';
use Mojolicious;
my $app = Mojolicious->new;
$ENV{MOJO_SERVER_ACCEPTS} = 31;
$ENV{MOJO_LISTEN}         = 'http://localhost:3001';
$p->_config_from_env($app->config, $p->config_map);
is $app->config->{hypnotoad}{accepts}, 31, 'config.hypnotoad.accepts';
is_deeply $app->config->{hypnotoad}{listen}, ['http://localhost:3001'],
  'config.hypnotoad.listen';

$ENV{MOJO_LISTEN} = 'http://localhost:3001  https://localhost:3002';
$p->_config_from_env($app->config, $p->config_map);
is_deeply $app->config->{hypnotoad}{listen},
  ['http://localhost:3001', 'https://localhost:3002'],
  'config.hypnotoad.listen';

note '_merge_config_map';
is int(keys %{$p->config_map->{hypnotoad}}), 14, 'config_map.hypnotoad';
is_deeply [$p->config_map->{hypnotoad}{listen}->()],
  [MOJO_LISTEN => [qr{\s+}]], 'config_map.hypnotoad.listen';

ok $p->config_map->{hypnotoad}{spare}, 'spare is set';
my %source = (
  foo       => sub {qw(a b)},
  hypnotoad => {listen => sub {qw(x y)}, spare => undef},
);
$p->_merge_config_map(\%source, $p->config_map);
is_deeply [$p->config_map->{hypnotoad}{listen}->()], [qw(x y)],
  'config_map.hypnotoad.listen merged';
is_deeply [$p->config_map->{foo}->()], [qw(a b)], 'config_map.foo merged';
ok !$p->config_map->{hypnotoad}{spare}, 'config_map.hypnotoad.spare is removed';

done_testing;
