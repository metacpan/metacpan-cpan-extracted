#!/usr/bin/env perl
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use Mojo::JSON;
use Data::Dumper;
use utf8;

use lib '../lib';

my $t = Test::Mojo->new;

my $app = $t->app;

$app->mode('production');

$app->plugin(Piwik => {
  url => 'sojolicious.example/piwik'
});

like($app->piwik_tag, qr{'://sojolicious\.example/piwik/'}, 'URL');
like($app->piwik_tag, qr{setSiteId',1}, 'SiteId');

like($app->piwik_tag(2), qr{'://sojolicious\.example/piwik/'}, 'URL');
like($app->piwik_tag(2), qr{setSiteId',2}, 'SiteId');

like($app->piwik_tag(
  2 => 'http://sojolicious.example/piwik/piwik.php'
), qr{'://sojolicious\.example/piwik/'}, 'URL');
like($app->piwik_tag(
  2 => 'http://sojolicious.example/piwik/piwik.php'
), qr{setSiteId',2}, 'SiteId');

like($app->piwik_tag(
  3 => 'https://sojolicious.example/piwik/piwik.js'
), qr{'://sojolicious\.example/piwik/'}, 'URL');
like($app->piwik_tag(
  3 => 'http://sojolicious\.example/piwik/piwik.js'
), qr{setSiteId',3}, 'SiteId');

like($app->piwik_tag(
  4 => 'sojolicious.example/piwik'
), qr{'://sojolicious\.example/piwik/'}, 'URL');

like($app->piwik_tag(
  4 => 'sojolicious.example/piwik'
), qr{setSiteId',4}, 'SiteId');

like($app->piwik_tag(
  4 => 'sojolicious.example/piwik'
), qr{'://sojolicious\.example/piwik/'}, 'URL');


$app->mode('development');

$app->plugin('Piwik' => {
  url => 'sojolicious.example/piwik'
});

ok(!$app->piwik_tag, 'Development mode');



done_testing;
