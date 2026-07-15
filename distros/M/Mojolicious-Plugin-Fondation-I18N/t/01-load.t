#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin;

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

# ─── Create app ──────────────────────────────────────────────────────────────

my $t = Test::Mojo->new('MyApp');
$t->app->log->level('error');

# ─── 1. Plugin loaded ────────────────────────────────────────────────────────

my $app = $t->app;
ok $app, 'app exists';

# ─── 2. I18N helpers ─────────────────────────────────────────────────────────

my $helpers = $app->renderer->helpers;
ok $helpers->{l},         'l() helper exists';
ok $helpers->{languages}, 'languages() helper exists';

# ─── 3. Fondation::I18N plugin is registered ─────────────────────────────────

my $manager = $app->fondation;
ok $manager, 'fondation manager exists';
ok $manager->registry->{'Mojolicious::Plugin::Fondation::I18N'},
    'Fondation::I18N is in the registry';

# ─── 4. Routes exist ─────────────────────────────────────────────────────────

$t->get_ok('/translate')->status_is(200, '/translate is reachable');
$t->get_ok('/raw')->status_is(200, '/raw is reachable');

# ─── 5. l() without I18N would return identity (Fondation core fallback) ─────
# Our I18N plugin is loaded, so it overrides the identity. Unknown text passes through.

$t->get_ok('/raw')->status_is(200)
  ->content_is('Unknown text', 'Unknown text passes through unchanged');

done_testing;
