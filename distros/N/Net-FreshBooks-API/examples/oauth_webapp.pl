#!/usr/bin/env perl

#
# Shamelessly pilfered from Net::Twitter's /example/oauth_webapp.pl
#

package MyWebApp;
use warnings;
use strict;
use base qw/HTTP::Server::Simple::CGI/;

use Net::FreshBooks::API;
use Data::Dump qw( dump );

# You can replace the consumer tokens with your own;
# these tokens are for the Net::FreshBooks::API example app.

my %consumer_tokens = (
    consumer_key    => 'netfreshbooksapi',
    consumer_secret => '5T9cCd9KsY96Kz5DzzHffig3BdSkeXAAs',
);

my $server_port  = 5003;
my $session_name = 'net-freshbooks-api-session';

sub fb {
    shift->{fb} ||= Net::FreshBooks::API->new( %consumer_tokens, @_,
        verbose => $ENV{FB_VERBOSE} );
}

my %dispatch = (
    '/oauth_callback' => \&oauth_callback,
    '/'               => \&my_first_client,
);

# all request start here
sub handle_request {
    my ( $self, $q ) = @_;

    my $request = $q->path_info;
    warn "Handling request for $request\n";

    my $handler = $dispatch{$request} || \&not_found;
    $self->$handler( $q );
}

# send the user to FreshBooks to authorize us
sub authorize {
    my ( $self, $q ) = @_;

    my $url = $self->url();

    my $oauth    = $self->fb->oauth;
    my $auth_url = $oauth->get_authorization_url(
        callback => $url . "oauth_callback" );

    # we'll store the request tokens in a session cookie
    my $cookie = $q->cookie(
        -name  => $session_name,
        -value => {
            request_token        => $oauth->request_token,
            request_token_secret => $oauth->request_token_secret,
        }
    );

    warn "Sending user to: $auth_url\n";
    print $q->redirect( -nph => 1, -uri => $auth_url, -cookie => $cookie );
}

# FreshBooks returns the user here
sub oauth_callback {
    my ( $self, $q ) = @_;

    my $request_token = $q->param( 'oauth_token' );
    my $verifier      = $q->param( 'oauth_verifier' );

    my %sess = $q->cookie( -name => $session_name );
    die "Something is horribly wrong"
        unless $sess{request_token} eq $request_token;

    $self->fb->oauth->request_token( $request_token );
    $self->fb->oauth->request_token_secret( $sess{request_token_secret} );

    warn <<"";
User returned from FreshBooks with:
    oauth_token    => $request_token
    oauth_verifier => $verifier


    # exchange the request token for access tokens
    my @access_tokens
        = $self->fb->oauth->request_access_token( verifier => $verifier );

    warn <<"";
Exchanged request tokens for access tokens:
    access_token        => $access_tokens[0]
    access_token_secret => $access_tokens[1]


    # we'll store the access tokens in a session cookie
    my $cookie = $q->cookie(
        -name  => $session_name,
        -value => {
            access_token        => $access_tokens[0],
            access_token_secret => $access_tokens[1],
        }
    );

    my $url = $self->url;
    
    warn "redirecting newly authorized user to $url\n";
    print $q->redirect(
        -nph    => 1,
        -uri    => $url,
        -cookie => $cookie
    );
}

# display a 404 Not found for any request we don't expect
sub not_found {
    my ( $self, $q ) = @_;

    print $q->header(
        -nph    => 1,
        -type   => 'text/html',
        -status => '404 Not found'
        ),
        $q->start_html,
        $q->h1( 'Not Found' ),
        $q->p( 'You appear to be lost. Try going home.' );
}

# Display a dump of the first client object returned by the iterator
sub my_first_client {
    my ( $self, $q ) = @_;

    # if the user is authorized, we'll get access tokens from a cookie
    my %sess = $q->cookie( $session_name );

    unless ( exists $sess{access_token_secret} ) {
        warn "User has no access_tokens\n";
        return $self->authorize( $q );
    }

    warn <<"";
Using access tokens:
   access_token        => $sess{access_token}
   access_token_secret => $sess{access_token_secret}
   

    my $oauth = $self->fb->oauth;
    $oauth->access_token( $sess{access_token} );
    $oauth->access_token_secret( $sess{access_token_secret} );

    my $client = $self->fb->client->list->next;
    my $rows   = '';
    my $cell_style
        = q[padding:4px 20px 4px 5px; border-bottom: 1px dotted #666; font-family: Arial,Helvetica,Sans-Serif;];
    my $count = 0;
    foreach my $field ( $client->field_names ) {

        my $content = $client->$field;
        $content = dump( $client->$field ) if $field eq 'links';
        my $style = $cell_style;
        $style .= "border-top: 1px dotted #666;" if $count == 0;
        $rows
            .= sprintf(
            '<tr><td style="%s">%s</td><td style="%s">%s</td></tr>',
            $style, $field, $style, $content );
        ++$count;
    }

    my $creds = "access token: " . $oauth->access_token . "\n";
    $creds .= "access token secret: " . $oauth->access_token_secret . "\n";

    print $q->header( -nph => 1 ),
        $q->start_html,
        $q->pre(
        "<p>$creds</p> <table border='0' cellpadding='0' cellspacing='0'>$rows</table>"
        ),
        $q->end_html;
}

sub url {
    my $url = $ENV{SERVER_URL};
    $url = 'http://' . $ENV{HTTP_HOST} . '/' if $ENV{HTTP_HOST};
    return $url;
}

my $app = MyWebApp->new( $server_port );
$app->run;
