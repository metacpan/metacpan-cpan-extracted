#!/usr/bin/env perl
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use Mojo::JSON;
use utf8;

use lib '../lib';

our $ft = 'auth.pl';

my $t = Test::Mojo->new;

my $app = $t->app;

$app->mode('production');

$app->plugin(Piwik => {
  url => 'sojolicio.us/piwik'
});

my $oo = $app->piwik_tag('opt-out');

like($oo, qr{http://sojolicio\.us/}, 'Opt-Out');
like($oo, qr{frameborder="no"}, 'Opt-Out');
like($oo, qr{height="200px"}, 'Opt-Out');
like($oo, qr{width="600px"}, 'Opt-Out');
like($oo, qr{^<iframe}, 'Opt-Out');
like($oo, qr{&amp;}, 'Opt-Out');

$oo = $app->piwik_tag('opt-out', 'width' => '100%');

like($oo, qr{http://sojolicio\.us/}, 'Opt-Out');
like($oo, qr{frameborder="no"}, 'Opt-Out');
like($oo, qr{height="200px"}, 'Opt-Out');
like($oo, qr{width="100%"}, 'Opt-Out');
like($oo, qr{^<iframe}, 'Opt-Out');
like($oo, qr{&amp;}, 'Opt-Out');

$oo = $app->piwik_tag('opt-out', 'frameborder' => 'yes');

like($oo, qr{http://sojolicio\.us/}, 'Opt-Out');
like($oo, qr{frameborder="yes"}, 'Opt-Out');
like($oo, qr{height="200px"}, 'Opt-Out');
like($oo, qr{width="600px"}, 'Opt-Out');
like($oo, qr{^<iframe}, 'Opt-Out');
like($oo, qr{&amp;}, 'Opt-Out');

$oo = $app->piwik_tag('opt-out', 'frameborder' => 'yes' => sub { 'No iframes supported'});

like($oo, qr{http://sojolicio\.us/}, 'Opt-Out');
like($oo, qr{frameborder="yes"}, 'Opt-Out');
like($oo, qr{height="200px"}, 'Opt-Out');
like($oo, qr{width="600px"}, 'Opt-Out');
like($oo, qr{^<iframe}, 'Opt-Out');
like($oo, qr{>No iframes supported<}, 'Opt-Out');
like($oo, qr{&amp;}, 'Opt-Out');


my $c = $app->build_controller;

$c->req->url(Mojo::URL->new('http:/khm.li/Rapunzel'));

$oo = $c->piwik_tag('opt-out');

like($oo, qr{http://sojolicio\.us/}, 'Opt-Out');

$c->req->url(Mojo::URL->new('https:/khm.li/Rapunzel'));

$oo = $c->piwik_tag('opt-out');

like($oo, qr{https://sojolicio\.us/}, 'Opt-Out');
like($oo, qr{iframe}, 'Opt-Out');

$oo = $c->piwik_tag('opt-out-link');

like($oo, qr{href="https://sojolicio\.us/piwik/index\.php\?module=CoreAdminHome&amp;action=optOut}, 'opt-out-link');
like($oo, qr{>Piwik Opt-Out<}, 'opt-out-link');
like($oo, qr{rel="nofollow"}, 'opt-out-link');

$oo = $c->piwik_tag('opt-out-link', sub { 'MyOptOut' });

like($oo, qr{href="https://sojolicio\.us/piwik/index\.php\?module=CoreAdminHome&amp;action=optOut}, 'opt-out-link');
like($oo, qr{>MyOptOut<}, 'opt-out-link');
like($oo, qr{rel="nofollow"}, 'opt-out-link');

$oo = $c->include(inline => "<%= piwik_tag 'opt-out-link', begin %>Opt Out!<% end %>");

like($oo, qr{<a href=".+" rel="nofollow">Opt Out!</a>}, 'opt-out-link');

done_testing;
