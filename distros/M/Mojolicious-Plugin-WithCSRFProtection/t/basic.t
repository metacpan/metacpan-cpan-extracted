#!/usr/bin/env perl
use Mojo::Base;

# turn off requiring explict inclusion because we're using Mojolicious::Lite
## no critic (Modules::RequireExplicitInclusion)

use Test::More tests => 32;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'WithCSRFProtection';

# Here we're setting up a route with a condition
post '/example_with_condition' => ( with_csrf_protection => 1 );

# Here we're using the shortcut.  This doesn't really make sense in the lite
# application, but makes sense in a full application, so we need to test it
# as well
app->routes->post('/example_with_shortcut')
    ->with_csrf_protection->to('example_with_shortcut');

# And this gets us the CSRF token, which we'll need to be able to test that
# this works okay.
get '/token' => sub {
    my ($c) = @_;
    $c->render( text => $c->csrf_token );
};

########################################################################

my $t = Test::Mojo->new;

# get the token
my $token = $t->get_ok('/token')->status_is(200)->tx->res->text;

for my $path (qw( example_with_condition example_with_shortcut )) {
    $t->post_ok("/$path")->status_is(403)
        ->content_like(qr/Failed CSRF check/);

    $t->post_ok("/$path?csrf_token=wrong")->status_is(403);

    $t->post_ok("/$path?csrf_token=$token")->status_is(200);

    $t->post_ok( "/$path" => form => { csrf_token => 'wrong' } )
        ->status_is(403);

    $t->post_ok( "/$path" => form => { csrf_token => $token } )
        ->status_is(200);

    $t->post_ok( "/$path" => { 'X-CSRF-Token' => 'wrong' } )->status_is(403);

    $t->post_ok( "/$path" => { 'X-CSRF-Token' => $token } )->status_is(200);
}

__DATA__

@@ example_with_condition.html.ep
<html><body>ok</body></html>

@@ example_with_shortcut.html.ep
<html><body>ok</body></html>
