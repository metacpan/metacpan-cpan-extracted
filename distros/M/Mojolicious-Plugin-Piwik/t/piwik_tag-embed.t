#!/usr/bin/env perl
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use Mojo::JSON;
use Data::Dumper;
use utf8;

my $t = Test::Mojo->new;

my $app = $t->app;

$app->plugin(Piwik => {
  url => 'sojolicio.us/piwik',
  site_id => 2
});

get '/embed' => sub {
  shift->render(inline => '<%= piwik_tag %>');
};

get '/embed-stash' => sub {
  shift->render(inline => "<p><% if (stash('piwik.embed')) { %>ok<% } else { %>not ok<% } %></p>");
};

# Nothing to embed
is($app->piwik_tag, '', 'No script embedded');
ok(!$app->defaults('piwik.embed'), 'Not embedded');

$t->get_ok('/embed')
  ->content_like(qr!^\s*$!);

$t->get_ok('/embed-stash')
  ->text_is('p', 'not ok');

$app->plugin(Piwik => {
  url => 'sojolicio.us/piwik',
  site_id => 2,
  embed => 1
});

like($app->piwik_tag, qr!_paq!, 'Script embedded');
ok($app->defaults('piwik.embed'), 'Not embedded');

$t->get_ok('/embed')
  ->content_like(qr!_paq!);

$t->get_ok('/embed-stash')
  ->text_is('p', 'ok');



done_testing;

__END__
