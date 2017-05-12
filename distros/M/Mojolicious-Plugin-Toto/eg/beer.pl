#!/usr/bin/env perl

package Beer;
use Mojo::Base 'Mojolicious::Controller';

sub browse {
    shift->render_text("this is a page to browse beer");
}

sub drink {
    my $c = shift;
    my $beer = $c->current_instance;
    return $c->render_exception("NO BEER");
    warn "ready to drink beer";
    return 1;
}

package Foo;
use Mojo::Base 'Mojolicious::Controller';

sub bar { shift->render_text("this is another controller (used by beer/list)"); }

package main;

use Mojolicious::Lite;
use lib './lib';

app->routes->namespaces(['main']);

get '/beer/list' => { controller => "Foo", action => 'bar', nav_item => 'beverage' } => 'beer/list';

get '/' => 'index';

plugin 'toto' =>
  prefix => 't',
  #model_namespace => 'Mojolicious::Plugin::Toto',
  nav => [
      'brewpub',          # Refers to a sidebar entry below
      'beverage'          # Refers to a sidebar entry below
  ],
  sidebar => {
    brewpub => [
        'brewery/phonelist',
        'brewery/mailing_list',
        'pub/search',
        'pub/map',
        'brewery',        # Refers to a "tab" entry below
        'pub',            # Refers to a "tab" entry below
    ],
    beverage =>
      [ 'beer/list',      # This will use the route defined above named "beer/list"
        'beer/create',
        'beer/search',
        'beer/browse',    # This will use the controller at the top (Beer::browse)
        'beer'            # Refers to a "tab" entry below
       ],
  },
  tabs => {
    brewery => [ 'view', 'edit', 'directions', 'beers', 'info' ],
    pub     => [ 'view', 'info', 'comments', 'hours' ],
    beer    => [ 'view', 'edit', 'pictures', 'notes', 'drink' ],
  };

app->start;

__DATA__
@@ index.html.ep

This is the landing page, all the toto stuff is
%= link_to 'brewpub' => begin
here
%= end

@@ beer/drink.html.ep
drinking beer <%= $beer %>

