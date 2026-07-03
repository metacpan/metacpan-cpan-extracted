#!usr/bin/env perl
use lib '../lib';
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;
my $app = $t->app;

plugin 'Localize';

my $c = $app->build_controller;
$c->req->headers->accept_language('de-DE, en-US, en');
$c->app($app);

is_deeply($c->localize->locale,
	  [qw/de-de de en-us en/],
	  'Languages (New)');
is_deeply($c->localize->locale('fr-FR'),
	  [qw/fr-fr fr de-de de en-us en/],
	  'Extend Languages');
is_deeply($c->localize->locale,
	  [qw/fr-fr fr de-de de en-us en/],
	  'Languages');

# Reset cache
delete $c->stash->{'localize.locale'};
is_deeply($c->localize->locale('fr-FR'),
	  [qw/fr-fr fr de-de de en-us en/],
	  'Extend Languages (New)');
is_deeply($c->localize->locale('de-DE'),
	  [qw/de-de de fr-fr fr en-us en/],
	  'Extend Languages (Unique)');

$c->req->headers->accept_language('de-DE, en-US, en, de-DE');
# Reset cache
delete $c->stash->{'localize.locale'};
is_deeply($c->localize->locale,
	  [qw/de-de de en-us en/],
	  'Languages (New)');

plugin Localize => {
  dict => {
    welcome => {
      _ => sub { $_->locale },
      -en => 'Welcome!',
      de => 'Willkommen!',
      fr => 'Bonjour!'
    }
  }
};

$c->stash('localize.locale' => undef);

# Create language depending routes in Mojolicious::Lite
under '/:lang' => { lang => '' } => sub {
  my $c = shift;

  # Prefer the chosen language
  $c->localize->locale($c->stash('lang')) if $c->stash('lang');
  return 1;
};

get '/' => sub {
  shift->render(inline => '<%= loc "welcome" %>');
};

$t->get_ok('/')->status_is(200)->content_is("Welcome!\n");
$t->get_ok('/' => { 'Accept-Language' => 'de-DE, en-US, en' })->status_is(200)->content_is("Willkommen!\n");
$t->get_ok('/' => { 'Accept-Language' => 'xx, fr, de-DE, en-US, en' })->status_is(200)->content_is("Bonjour!\n");
$t->get_ok('/' => { 'Accept-Language' => 'DE, en-US, en' })->status_is(200)->content_is("Willkommen!\n");

$t->get_ok('/en/')->status_is(200)->content_is("Welcome!\n");
$t->get_ok('/de/')->status_is(200)->content_is("Willkommen!\n");
$t->get_ok('/fr/')->status_is(200)->content_is("Bonjour!\n");

$t->get_ok('/xx/')->status_is(200)->content_is("Welcome!\n");


done_testing;
