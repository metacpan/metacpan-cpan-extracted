#!/usr/bin/env perl
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use Mojo::JSON;
use Data::Dumper;
use utf8;

my $t = Test::Mojo->new;

my $app = $t->app;

$app->mode('production');

$app->plugin(Piwik => {
  url => 'sojolicious.example/piwik',
  site_id => 2,
  append => 'console.log("check")'
});

like($app->piwik_tag, qr{'://sojolicious\.example/piwik/'}, 'URL');
like($app->piwik_tag, qr{setSiteId',2}, 'SiteId');
like($app->piwik_tag, qr{;console\.log\("check"\)}, 'Append');

# Define shortcut
ok(any('/piwik/tracker.js')->piwik('track_script'), 'Track script is set');

$t->get_ok('/piwik/tracker.js')
  ->status_is(200)
  ->content_like(qr!'http://sojolicious\.example/piwik/piwik\.php'!)
  ->content_like(qr!'setSiteId',2!)
  ->content_like(qr!;console\.log\(\"check\"\)!)
  ->header_is('Content-Type','application/javascript')
  ->header_is('Cache-Control', 'max-age=10800')
  ;

$app->plugin(Piwik => {
  url => 'sojolicious.example/piwik',
  site_id => 2,
  append => 444
});

like($app->piwik_tag, qr{'://sojolicious\.example/piwik/'}, 'URL');
like($app->piwik_tag, qr{setSiteId',2}, 'SiteId');
like($app->piwik_tag, qr{;444}, 'Append');


done_testing;

__END__
