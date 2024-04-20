use v5.26;
use warnings;

use Test2::V0;
use Mojolicious::Lite;

plugin 'Module::Loader' => {command_namespaces => ['MyApp::Command']};

is(pop(app->commands->namespaces->@*), 'MyApp::Command', 'added to command namespace at registration time');

done_testing;
