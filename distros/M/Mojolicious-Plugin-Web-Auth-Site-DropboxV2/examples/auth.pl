#!/usr/bin/env perl

use strict;
use warnings;

=head1 SYNOPSIS

    perl -Ilib examples/auth.pl daemon -m development -l http://*:8088

In your browser go to http://localhost:8088/

=head2 ACKNOWLEDGEMENTS

This code is mostly copied from the examples in
L<Mojolicious::Plugin::Web::Auth>.

=cut

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Config::Pit qw( pit_get );
use Data::Printer;
use Mojolicious::Lite;
use String::CamelCase qw( camelize );

my $site = 'dropboxv2';

my $module = camelize($site);
helper site => sub { $site };

my $pit = pit_get(
    $site,
    require => {
        key    => ucfirst($site) . ' Client ID',
        secret => ucfirst($site) . ' Client Secret',
    }
);

plugin 'Mojolicious::Plugin::Web::Auth',
    module      => 'DropboxV2',
    key         => $pit->{key},
    secret      => $pit->{secret},
    user_info   => 0,
    on_finished => sub {
    my ( $c, $access_token, $account_info, $extra ) = @_;
    p $account_info;
    $c->session( access_token => $access_token );
    $c->session( extra        => $extra );
    return $c->redirect_to('index');
    };

get '/' => sub {
    my ($c) = @_;
    unless ( $c->session('access_token') ) {
        use DDP;
        p $c->session;
        return $c->redirect_to('login');
    }
} => 'index';

any [qw/get post/] => '/login' => sub {
    my ($c) = @_;
    if ( uc $c->req->method eq 'POST' ) {
        return $c->redirect_to(
            sprintf( "/auth/%s/authenticate", lc $site ) );
    }
} => 'login';

post '/logout' => sub {
    my ($c) = @_;
    $c->session( expires => 1 );
    $c->redirect_to('index');
} => 'logout';

app->secrets( ['dropbox'] );
app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% use DDP;
<%= site %> access token: <%= session('access_token') %>
% my $extra = session('extra');
extra: <pre><%= np $extra %></pre>
<form method="post" action="/logout">
<button type="submit">Log out</button>
</form>

@@ login.html.ep
% layout 'default';
<form method="post">
<button type="submit">Log in with <%= ucfirst( site ) %></button>
</form>

@@ layouts/default.html.ep
% title 'Auth' . ucfirst(lc site);
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
