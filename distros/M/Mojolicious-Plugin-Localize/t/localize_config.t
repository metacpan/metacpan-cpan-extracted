#!/usr/bin/env perl
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;
use Data::Dumper;
use utf8;

my $t = Test::Mojo->new;
my $app = $t->app;

$app->plugin(Config => {
  file => $app->home . '/dictionary.conf'
});

$app->plugin('Localize');

is(${app->localize->dictionary->{welcome}->{en}}, 'Welcome', 'Welcome');

my $c = $app->build_controller;

$c->req->headers->accept_language('de-DE, en-US, en');
is($c->loc('welcome'), 'Willkommen', 'Welcome (de)');

$c->req->headers->accept_language('en-US, en');
delete $c->stash->{'localize.locale'};
is($c->loc('welcome'), 'Welcome', 'Welcome (en)');

$app->plugin('Localize' => {
  resources => ['dictionary2.dict', 'dictionary3.dict']
});

delete $c->stash->{'localize.locale'};
is($c->loc('welcome_de'), 'Willkommen', 'Welcome (de)');
is($c->loc('welcome_pl'), 'Serdecznie witamy', 'Welcome (pl)');
is($c->loc('welcome_bg'), 'добре дошъл', 'Welcome (pl)');

done_testing;
