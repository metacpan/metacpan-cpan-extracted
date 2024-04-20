use v5.26;
use warnings;

use Test2::V0;
use Mojolicious::Lite;

push(@INC, 't/lib');

plugin 'Module::Loader';

is(
  warning {
    plugin 'Module::Loader' => {plugin_namespaces => ['MyApp::Plugin']}
  },
  "MyApp::Plugin::Test Loaded\n",
  'call add_plugin_namespace'
);

done_testing;
