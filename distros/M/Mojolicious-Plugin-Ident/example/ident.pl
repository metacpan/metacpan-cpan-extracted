#!/usr/bin/env perl

use Mojolicious::Lite;

plugin 'ident';

# helper to get the controller
helper c => sub { shift };

get '/' => 'index';

under sub {
  my($self) = @_;

  return 1 if eval { $self->ident->same_user };

  $self->render(status => 403, template => 403);
  return;
};

get '/private' => 'private';

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'ident test';
<table>
  <tr>
    <td>username:</td>
    <td><%= ident->username %></td>
  </tr>
  </tr>
    <td>os</td>
    <td><%= ident->os %></td>
  </tr>
  <tr>
    <td>local</td>
    <td><%= c->tx->local_address %>:<%= c->tx->local_port %></td>
  </tr>
  <tr>
    <td>remote</td>
    <td><%= c->tx->remote_address %>:<%= c->tx->remote_port %></td>
  </tr>
</table>

@@ private.html.ep
% layout 'default';
% title 'ident test';
<p>you are in the private area</p>

@@ 403.html.ep
% layout 'default';
% title 'Forbidden';
<h1>403 Forbidden</h1>
<p>You do not have permission to access this resource</p>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
