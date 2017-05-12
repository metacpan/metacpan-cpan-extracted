#!/usr/bin/env perl

use Mojo::Base -strict;

# Disable IPv6 and libev
BEGIN {
    $ENV{MOJO_NO_IPV6} = 1;
    $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More;
 
use Mojolicious::Lite;
use Test::Mojo;

plugin 'MethodOverride',
    header => 'X-HTTP-Test-Override',
    param => 'x-test-tunnel-method';

if (app->can('secrets')) {
    app->secrets(['mpmo.test']);
}
elsif (app->can('secret')) {
    app->secret('mpmo.test');
}

any [qw(GET POST PUT DELETE)] => '/welcome' => sub {
    my $self = shift;
    my $method = uc $self->req->method;

    $self->render(
        data => "$method the Mojolicious real-time web framework!\n"
    );
};


my $t = Test::Mojo->new;

$t->post_ok('/welcome', {'X-HTTP-Test-Override' => 'GET'})
  ->status_is(200)
  ->content_like(qr/GET the Mojolicious /);
$t->post_ok('/welcome', {'X-HTTP-Test-Override' => 'POST'})
  ->status_is(200)
  ->content_like(qr/POST the Mojolicious /);
$t->post_ok('/welcome', {'X-HTTP-Test-Override' => 'PUT'})
  ->status_is(200)
  ->content_like(qr/PUT the Mojolicious /);
$t->post_ok('/welcome', {'X-HTTP-Test-Override' => 'DELETE'})
  ->status_is(200)
  ->content_like(qr/DELETE the Mojolicious /);

$t->post_ok('/welcome', {'X-HTTP-Method-Override' => 'PUT'})
  ->status_is(200)
  ->content_unlike(qr/PUT the Mojolicious /)
  ->content_like(qr/POST the Mojolicious /);

$t->post_ok('/welcome?x-test-tunnel-method=GET')
  ->status_is(200)
  ->content_like(qr/GET the Mojolicious /);
$t->post_ok('/welcome?x-test-tunnel-method=POST')
  ->status_is(200)
  ->content_like(qr/POST the Mojolicious /);
$t->post_ok('/welcome?x-test-tunnel-method=PUT')
  ->status_is(200)
  ->content_like(qr/PUT the Mojolicious /);
$t->post_ok('/welcome?x-test-tunnel-method=DELETE')
  ->status_is(200)
  ->content_like(qr/DELETE the Mojolicious /);

$t->post_ok('/welcome?x-tunneled-method=GET')
  ->status_is(200)
  ->content_unlike(qr/GET the Mojolicious /)
  ->content_like(qr/POST the Mojolicious /);

done_testing;
