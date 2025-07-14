# t/morelog.t
use strict;
use warnings;
use Test::More;
use Test::Mojo;

use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/../lib"; # Adjust if plugin is in lib/

plugin 'MoreLog';

# Add a test route that uses the plugin
get '/test_printf' => sub {
    my $c = shift;
    $c->app->log->printf("Testing printf: %s = %d", 'foo', 42);
    $c->render(text => 'ok');
};

get '/test_dump' => sub {
    my $c = shift;
    $c->app->log->dump({ foo => 'bar', baz => [1,2,3] });
    $c->render(text => 'ok');
};

my $t = Test::Mojo->new;

$t->get_ok('/test_printf')->status_is(200)->content_is('ok');
$t->get_ok('/test_dump')->status_is(200)->content_is('ok');

done_testing;
