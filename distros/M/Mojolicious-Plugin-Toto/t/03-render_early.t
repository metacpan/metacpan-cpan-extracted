#!perl

package Door;
use Mojo::Base 'Mojolicious::Controller';

sub create {
    my $c = shift;
    return $c->render( text => 'closed' ) if $c->param('close');
    $c->render(param => "thing");
}

sub open {
    my $c = shift;
    return $c->render( text => 'closed' ) if $c->param('close');
    $c->render(param => "thing");
}

package MyApp;
use Mojolicious::Lite;

app->renderer->classes(['main']);
app->routes->namespaces(['main']);

plugin toto => {
    nav     => [qw/house/],
    sidebar => { house => [qw(door/create door)] },
    tabs    => { door => [qw/open/]},
};

app->defaults(layout => 'default');

package main;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new();

$t->get_ok('/door/create')->status_is(200)->content_is("this thing is a door\n");
$t->get_ok('/door/create?close=1')->status_is(200)->content_is("closed");
$t->get_ok('/door/open/12')->status_is(200)->content_is("this thing is open\n");
$t->get_ok('/door/open/12?close=1')->status_is(200)->content_is("closed");

done_testing();

1;

__DATA__
@@ not_found.html.ep
% layout 'default';
NOT FOUND : <%= $self->req->url->path %>

@@ door/create.html.ep
this <%= $param %> is a door

@@ door/open.html.ep
this <%= $param %> is open
