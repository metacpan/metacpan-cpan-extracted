use v5.26;
use warnings;

use Test2::V0;
use Mojolicious::Lite;
use Test::Mojo;

push(@INC, 't/lib');

plugin 'Module::Loader';

app->add_controller_namespace('MyApp::Controller');

get('/welcome')->to(controller => 'Test', action => 'hello_world');

my $t = Test::Mojo->new();
$t->get_ok('/welcome')->status_is(200)->content_is("Hello World");

done_testing;
