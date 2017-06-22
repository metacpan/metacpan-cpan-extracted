#!/usr/bin/env perl
use Mojolicious::Lite;
use Test::Mojo;
use Test::More;

app->secrets(['abcdefghijklmnopqrstuvwxyz']);

plugin 'ClosedRedirect';

my $prefix = '/instance/example';

my $t = Test::Mojo->new;

my $c = $t->app->build_controller;

$c->req->url->base->path($prefix);

is($c->url_for, 'instance/example', 'URL with base');

app->hook(
  before_dispatch => sub {
    my $c = shift;
    $c->req->url->base->path($prefix);
  }
);

# Relative redirect
get '/instance/example/login' => sub {
  my $c = shift;
  my $v = $c->validation;
  $v->optional('fwd')->closed_redirect;

  unless ($v->has_error) {
    my $return_url = $v->param('fwd');
    return $c->relative_redirect_to($return_url);
  };
  return $c->render(text => 'error');
};

# Not relative
get '/instance/example/login-not-relative' => sub {
  my $c = shift;
  my $v = $c->validation;
  $v->optional('fwd')->closed_redirect;

  unless ($v->has_error) {
    my $return_url = $v->param('fwd');

    # warn 'redirect to!;
    return $c->redirect_to($return_url);
  };
  return $c->render(text => 'error');
};


my $url = $c->url_for('/login')->query([
  fwd => $c->close_redirect_to('/my/path')
]);

is($url, '/instance/example/login?fwd=%2Finstance%2Fexample%2Fmy%2Fpath%3Fcrto%3Df6f4758e06332a81361dc57f50810abda4c07bb6', 'Return url with base');

$t->get_ok($url)->status_is(302)
  ->header_is('location', '/instance/example/my/path');



# Check with non-relative redirect
my $url_fail = $c->url_for('/login-not-relative')->query([
  fwd => $c->url_for('/my/path')
]);

is($url_fail, '/instance/example/login-not-relative?fwd=%2Finstance%2Fexample%2Fmy%2Fpath',
   'Return url with base');

$t->get_ok($url_fail)->status_is(302)
  ->header_is('location', '/instance/example/instance/example/my/path');



done_testing;
__END__

