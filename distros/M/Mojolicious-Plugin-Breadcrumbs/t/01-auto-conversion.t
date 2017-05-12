#!perl

use Test::More;
use Test::Mojo;
use Mojolicious;
use utf8;

my $t = Test::Mojo->new( Mojolicious->new );
$t->app->plugin('Breadcrumbs');
$t->app->routes->get('/' => 'index');
$t->app->routes->get('/user/account-settings' => 'account-settings');

$t->get_ok('/')->status_is(200)->content_is(
    'You are at <section class="breadcrumbs">'
    . '<span class="last_breadcrumb">Home</span>'
    . "</section>\n"
);

$t->get_ok('/user/account-settings')->status_is(200)->content_is(
    'You are at <section class="breadcrumbs">'
    . '<a href="/">Home</a><span class="breadcrumb_sep">▸</span>'
    . '<a href="/user">User</a><span class="breadcrumb_sep">▸</span>'
    . '<span class="last_breadcrumb">Account settings</span>'
    . "</section>\n"
);

done_testing();

__DATA__

@@ index.html.ep

You are at <%== breadcrumbs %>

@@ account-settings.html.ep

You are at <%== breadcrumbs %>