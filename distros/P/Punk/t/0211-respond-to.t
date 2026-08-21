#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# Accept negotiation ($c->respond_to, punk_accept.h). The assertions worth
# having are the ones naive substring matching fails: a real browser Accept
# line is ordered by q-value, q=0 is an exclusion rather than a mention, an
# indifferent client that itself sent JSON gets JSON back, and every outcome
# carries Vary: Accept so a shared cache cannot hand one client's format to
# another.

{
    package NApp;
    use Punk;

    get '/page' => sub {
        my ($c) = @_;
        $c->respond_to(
            json => sub { $_[0]->json({ kind => 'json' }) },
            html => sub { $_[0]->html('<p>html</p>') },
        );
    };
    get '/typed' => sub {
        my ($c) = @_;
        $c->respond_to(
            'application/vnd.book+json' => sub { $_[0]->json({ kind => 'vnd' }) },
            json                        => sub { $_[0]->json({ kind => 'json' }) },
        );
    };
    get '/fallback' => sub {
        my ($c) = @_;
        $c->respond_to(
            json => sub { $_[0]->json({ kind => 'json' }) },
            any  => sub { $_[0]->text('caught') },
        );
    };
    get '/merge' => sub {
        my ($c) = @_;
        $c->header(Vary => 'Accept-Encoding');
        $c->respond_to(json => sub { $_[0]->json({ kind => 'json' }) });
    };
    get '/bad' => sub {
        my ($c) = @_;
        $c->respond_to(sideways => sub { $_[0]->text('never') });
    };
    post '/echo' => sub {
        my ($c) = @_;
        $c->respond_to(
            html => sub { $_[0]->html('<p>html</p>') },
            json => sub { $_[0]->json({ kind => 'json' }) },
        );
    };
}

my $t = Punk::Test->new('NApp');

# ---- ordinary picks -----------------------------------------------------------

$t->get_ok('/page', headers => {
      Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' })
  ->status_is(200)
  ->header_like('Content-Type' => qr{^text/html})
  ->content_is('<p>html</p>');
is($t->header('Vary'), 'Accept', 'a negotiated response varies on Accept');

$t->get_ok('/page', headers => { Accept => 'application/json' })
  ->status_is(200)
  ->header_is('Content-Type' => 'application/json')
  ->json_is('/kind' => 'json');

$t->get_ok('/page', headers => { Accept => 'text/html;q=0.4,application/json;q=0.9' })
  ->json_is('/kind' => 'json', 'q-values order the choice, not position');

$t->get_ok('/page', headers => { Accept => 'text/html;q=0, */*' })
  ->json_is('/kind' => 'json', 'q=0 excludes a format rather than matching it');

$t->get_ok('/typed', headers => { Accept => 'application/vnd.book+json' })
  ->json_is('/kind' => 'vnd', 'a full media type names an exact format');

$t->get_ok('/typed', headers => { Accept => 'application/json' })
  ->json_is('/kind' => 'json', 'and its sibling still resolves normally');

# ---- the indifferent client ----------------------------------------------------

$t->get_ok('/page')
  ->json_is('/kind' => 'json',
      'no Accept at all falls to the first registered format');

$t->get_ok('/page', headers => { Accept => '*/*' })
  ->json_is('/kind' => 'json', 'a bare wildcard does the same');

$t->post_ok('/echo', headers => { Accept => '*/*' }, json => { in => 1 })
  ->json_is('/kind' => 'json',
      'an indifferent client that sent JSON gets JSON back, not the '
    . 'first-registered HTML');

# ---- nothing fits --------------------------------------------------------------

$t->get_ok('/page', headers => { Accept => 'image/png' })
  ->status_is(406)
  ->json_is('/errors/0/message' => 'Not Acceptable');
is($t->header('Vary'), 'Accept', 'the 406 varies on Accept too');

$t->get_ok('/fallback', headers => { Accept => 'image/png' })
  ->status_is(200)
  ->content_is('caught', 'an `any` branch catches what nothing else fits');

# ---- Vary merging --------------------------------------------------------------

$t->get_ok('/merge', headers => { Accept => 'application/json' });
is($t->header('Vary'), 'Accept-Encoding, Accept',
    'an existing Vary gains the Accept token instead of a second pair');

# ---- misuse --------------------------------------------------------------------

$t->get_ok('/bad', headers => { Accept => 'application/json' })
  ->status_is(500, 'an unknown format name croaks (and the dispatcher '
                 . 'turns the die into the 500)');

done_testing;
