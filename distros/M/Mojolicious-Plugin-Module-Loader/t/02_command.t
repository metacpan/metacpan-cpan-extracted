use v5.26;
use warnings;

use Test2::V0;
use Mojolicious::Lite;

plugin 'Module::Loader';

ok(no_warnings {app->add_command_namespace('MyApp::Command')}, 'call add_command_namespace');

is(pop(app->commands->namespaces->@*), 'MyApp::Command', 'added to command namespace');

done_testing;
