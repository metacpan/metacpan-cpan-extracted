#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin;

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

# ─── Create app ──────────────────────────────────────────────────────────────

my $t = Test::Mojo->new('MyApp');
my $app = $t->app;
$app->log->level('error');

# ─── 1. Identity fallback: unknown text passes through ───────────────────────

$t->get_ok('/raw')->status_is(200)
  ->content_is('Unknown text', 'Unknown text passes through unchanged');

# ─── 2. Default language (English): l('Welcome') stays 'Welcome' ─────────────

$t->get_ok('/translate')->status_is(200)
  ->content_is('Welcome', 'Default language is English');

# ─── 3. French via Accept-Language header ────────────────────────────────────

$t->get_ok('/translate' => {'Accept-Language' => 'fr'})
  ->status_is(200)
  ->content_is('Bienvenue', 'Accept-Language: fr → Bienvenue');

# ─── 4. JS i18n endpoint ─────────────────────────────────────────────────────

$t->get_ok('/i18n/fr.json')->status_is(200, '/i18n/fr.json is reachable');

my $json = $t->tx->res->json;
ok $json, 'JSON response is valid';
is $json->{Welcome}, 'Bienvenue', 'JSON has French translation for Welcome';
is $json->{Home},    'Accueil',   'JSON has Home translation';

# ─── 5. Unknown language returns 404 ─────────────────────────────────────────

$t->get_ok('/i18n/xx.json')->status_is(404, 'Unknown language returns 404');

# ─── 6. languages() helper ───────────────────────────────────────────────────

my $c = $app->build_controller;
$c->languages('fr');
is $c->languages, 'fr', 'languages() returns current language';
is $c->l('Welcome'), 'Bienvenue', 'l() uses language set by languages()';

$c->languages('en');
is $c->languages, 'en', 'languages() switch to English works';
is $c->l('Welcome'), 'Welcome', 'l() returns identity for English (no en lexicon)';

done_testing;
