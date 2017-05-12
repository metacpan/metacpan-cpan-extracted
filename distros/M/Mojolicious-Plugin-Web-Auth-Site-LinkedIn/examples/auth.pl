#!/usr/bin/env perl

use strict;
use warnings;

=head1 SYNOPSIS

    perl -Ilib examples/auth.pl daemon -m production -l http://*:8088

In your browser go to http://localhost:8088/

=head2 ACKNOWLEDGEMENTS

This code is mostly copied from the examples in
L<Mojolicious::Plugin::Web::Auth>.

=cut

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Mojolicious::Lite;
use Config::Pit;

print STDERR
    "[NOTICE] should be used in domains other than 'localhost' (e.g. local.example.com)\n";

my $site   = 'linkedin';
helper site => sub { $site };

my $pit = pit_get(
    $site,
    require => {
        key    => ucfirst($site) . ' Client ID',
        secret => ucfirst($site) . ' Client Secret',
    }
);

plugin 'Mojolicious::Plugin::Web::Auth',
    module      => ucfirst($site),
    key         => $pit->{key},
    secret      => $pit->{secret},
    on_finished => sub {
    my ( $c, $access_token, $account_info ) = @_;
    $c->session( 'access_token' => $access_token );
    $c->session( 'account_info' => $account_info );
    return $c->redirect_to('index');
    };

get '/' => sub {
    my ($c) = @_;
    unless ( $c->session('account_info') ) {
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

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
Hello <%= session('account_info')->{data}->{username} %>@<%= site %>
<form method="post" action="/logout">
<button type="submit">Logout</button>
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
