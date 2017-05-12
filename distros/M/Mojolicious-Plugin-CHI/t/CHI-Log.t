#!/usr/bin/env perl
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use File::Temp qw/:POSIX tempdir/;
use File::Path qw/remove_tree/;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::CHI';

my $t = Test::Mojo->new;
my $app = $t->app;

my $c = Mojolicious::Controller->new;
$c->app($app);

my $path = tempdir(CLEANUP => 1);

$app->plugin(CHI => {
  default => {
    driver => 'File',
    root_dir => $path
  }
});

Mojo::IOLoop->start;

my $string = '';
$app->log->on(
  message => sub {
    shift;
    $string .= join '---', @_;
  });

$app->log->debug('test');
is($string, 'debug---test', 'Check log');

ok($c->chi->set('key_1' => 'value_1'), 'Set key');
is($c->chi->get('key_1'), 'value_1', 'Get key');

opendir(D, $path);
my @test = readdir(D);
closedir(D);

ok(join(',', @test) =~ m/Default/, 'Namespace option valid');

remove_tree($path);

ok(!-d $path, 'Directory does not exist');

# Cache is automatically recreated
ok($c->chi->set('key_2' => 'value_2'), 'Set key');
is($c->chi->get('key_2'), 'value_2', 'Get key');

ok(-d $path, 'Directory does not exist');

remove_tree($path . '/Default');

ok(open(my $f, '>' . $path . '/Default'), 'Touch file');

# Cache is automatically recreated
$string = '';
ok($c->chi->set('key_3' => 'value_3'), 'Set key');
like($string, qr/^warn---error during cache set/, 'Set error log');

ok(!$c->chi->get('key_3'), 'Get key');

done_testing;
