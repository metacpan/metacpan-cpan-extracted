#!/usr/bin/env perl
use strict;
use warnings;

use lib '../lib';

use Test::More;
use Test::Mojo;
use Mojo::ByteStream 'b';
use Mojolicious::Lite;

my $t = Test::Mojo->new;
my $app = $t->app;
$app->plugin('WebFinger');
my $c = $app->build_controller;

my $webfinger_host = 'webfing.er';
my $acct = 'acct:akron@webfing.er';

# Rewrite req-url
$c->req->url->base->parse('http://'.$webfinger_host);
$app->hook(
  before_dispatch => sub {
    for (shift->req->url->base) {
      $_->host($webfinger_host);
      $_->scheme('http');
    }
  });


is($c->hostmeta->link('lrdd')->attr('template'),
   'http://'.$webfinger_host.'/.well-known/webfinger?resource={uri}',
   'Correct uri');

is ($c->endpoint(webfinger => { uri => $acct, '?' => undef }),
    'http://'.$webfinger_host.'/.well-known/webfinger?resource=' . b($acct)->url_escape,
    'Webfinger endpoint');

app->callback(
  prepare_webfinger =>
    sub {
      my ($c, $norm) = @_;
      return 1 if index($norm, $acct) >= 0;
    });

$app->hook(
  before_serving_webfinger =>
    sub {
      my ($c, $norm, $xrd) = @_;

      if ($norm eq $acct) {
	$xrd->link('http://microformats.org/profile/hcard' => {
	  type => 'text/html',
	  href => 'http://sojolicio.us/akron.hcard'
	});
	$xrd->link('describedby' => {
	  type => 'application/rdf+xml',
	  href => 'http://sojolicio.us/akron.foaf'
	});
      }

      else {
	$xrd = undef;
      };
    });

my $wf = $c->webfinger($acct);

ok($wf, 'Webfinger');
is($wf->subject, $acct, 'Subject');

is($wf->link('http://microformats.org/profile/hcard')
     ->attr('href'), 'http://sojolicio.us/akron.hcard',
   'Webfinger-hcard');
is($wf->link('http://microformats.org/profile/hcard')
     ->attr('type'), 'text/html',
   'Webfinger-hcard-type');
is($wf->link('describedby')
     ->attr('href'), 'http://sojolicio.us/akron.foaf',
   'Webfinger-described_by');
is($wf->link('describedby')
     ->attr('type'), 'application/rdf+xml',
   'Webfinger-descrybed_by-type');

$t->get_ok('/.well-known/webfinger?resource='.b($acct)->url_escape . '&format=xml')
  ->status_is('200')
  ->content_type_is('application/xrd+xml')
  ->text_is('Subject' => $acct);

$t->get_ok('/.well-known/webfinger?resource=nothing&format=xml')
  ->status_is('404')
  ->content_type_is('application/xrd+xml')
  ->text_is(Subject => 'nothing');

$t->get_ok('/.well-known/webfinger?resource='.b($acct)->url_escape)
  ->status_is('200')
  ->content_type_is('application/jrd+json')
  ->json_has('/subject' => $acct);

$t->get_ok('/.well-known/webfinger?resource=nothing')
  ->status_is('404')
  ->content_type_is('application/jrd+json')
  ->json_has('/subject' => 'nothing');

$app->callback(
  prepare_webfinger => sub {
    my ($c, $acct) = @_;
    return 1 if lc($acct) eq 'acct:akron@webfing.er';
  });

$app->hook(
  before_serving_webfinger => sub {
    my ($c, $acct, $xrd) = @_;

    if (lc($acct) eq 'acct:akron@webfing.er') {
      $xrd->link(author => 'Nils Diewald');
    };
  });

$acct = 'akron@webfing.er';

$t->get_ok('/.well-known/webfinger?resource='.b($acct)->url_escape)
  ->status_is('200')
  ->content_type_is('application/jrd+json')
  ->json_has('/subject' => $acct);

my ($alias) = $c->webfinger('akron')->alias;
is($alias, 'acct:akron@webfing.er', 'Webfinger');

# Remote tests

sub _rev {
  local $_ = join('',reverse(split('', shift)));
  y/@!/!@/;
  return $_;
};


done_testing(29);
exit;

$wf = $c->webfinger(_rev('es.rettiuq!norka'));

is($wf->subject, 'acct:' . _rev('es.rettiuq!norka'), 'Subject');
is($wf->link('http://webfinger.net/rel/profile-page')->attr('href'),
 'https://quitter.se/akron', 'Profile');


$wf = $c->webfinger(_rev('moc.liamg!dlaweid.slin'));

is($wf->subject, 'acct:' . _rev('moc.liamg!dlaweid.slin'), 'Subject');

is($wf->link('http://portablecontacts.net/spec/1.0')->attr('href'),
   'http://www-opensocial.googleusercontent.com/api/people/', 'PoCo');

$wf = $c->webfinger(_rev('su.tatsr!eikliw'));
is(_rev($wf->subject), 'su.tatsr!eikliw:tcca', 'Subject');
is($wf->link('http://webfinger.net/rel/profile-page')->attr('href'), 'https://rstat.us/users/wilkie', 'Subject');
ok($wf->link('magic-public-key'), 'MagicKey');

$c->delay(
  sub {
    my $delay = shift;
    $c->webfinger(_rev('moc.liamg!dlaweid.slin') => $delay->begin(0,1));
    $c->webfinger(_rev('su.tatsr!eikliw') => $delay->begin(0,1));
    $c->webfinger(_rev('moc.esrevidef!nakre') => $delay-begin(0,1));
  },
  sub {
    my $delay = shift;
    my ($nils_wf, $wilkie_wf, $fediverse_wf) = @_;

    is($nils_wf->subject, 'acct:' . _rev('moc.liamg!dlaweid.slin'), 'Gmail (in Parallel)');
    is($wilkie_wf->subject, 'acct:' . _rev('su.tatsr!eikliw'), 'Rstat.us (in Parallel)');
    is($fediverse_wf->subject, 'acct:' . _rev('moc.esrevidef!nakre'), 'Fediverse (in Parallel)');
  }
);

done_testing;
exit;
__END__
