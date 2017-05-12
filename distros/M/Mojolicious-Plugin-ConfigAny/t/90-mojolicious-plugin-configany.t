use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
my $module = 'Mojolicious::Plugin::ConfigAny';
use_ok($module);

plugin 'ConfigAny';

my $t = Test::Mojo->new;

my @dirs = $t->app->config_dirs;

is scalar(@dirs), 1, 'Got config dirs';

my @files = $t->app->config_files;

is scalar(@files), 2, 'Got config files';
is scalar keys %{$t->app->config}, 2, 'Parse config correctly';
done_testing;

