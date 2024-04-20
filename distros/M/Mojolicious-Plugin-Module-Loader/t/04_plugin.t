use v5.26;
use warnings;

use Test2::V0;
use Mojolicious::Lite;

push(@INC, 't/lib');

plugin 'Module::Loader';

is(warning {app->add_plugin_namespace('MyApp::Plugin')}, "MyApp::Plugin::Test Loaded\n", 'call add_plugin_namespace');

done_testing;
