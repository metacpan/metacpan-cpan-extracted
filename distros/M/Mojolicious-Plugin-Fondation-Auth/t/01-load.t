#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin;

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../Mojolicious-Plugin-Fondation-Model-DBIx-Async/lib";

# ─── Create app ──────────────────────────────────────────────────────────────

my $t = Test::Mojo->new('MyApp');
$t->app->log->level('error');

# ─── 1. Plugin loaded ────────────────────────────────────────────────────────

my $app = $t->app;
ok $app, 'app exists';

# ─── 2. Authentication helpers (helpers are in renderer->helpers, not ->can) ─

my $helpers = $app->renderer->helpers;
ok $helpers->{auth_form},             'auth_form helper exists';
ok $helpers->{authenticate},          'authenticate helper exists';
ok $helpers->{is_user_authenticated}, 'is_user_authenticated helper exists';
ok $helpers->{current_user},          'current_user helper exists';
ok $helpers->{logout},                'logout helper exists';

# ─── 3. Routes exist ─────────────────────────────────────────────────────────

my $routes  = $app->routes;
my @children = @{$routes->children};
my @names    = map { $_->name } @children;
# The route name might be auto-set or empty. Check via pattern string instead.
# Find routes by making requests and checking they don't 404.

$t->get_ok('/login')->status_is(200, '/login is reachable');
$t->get_ok('/logout')->status_is(403, '/logout requires authentication');
$t->get_ok('/public')->status_is(200, '/public is reachable');
$t->get_ok('/protected')->status_is(403, '/protected is reachable');

# ─── 4. Login form renders with provider template ────────────────────────────

$t->get_ok('/login')
  ->content_like(qr/<form/, 'login form has form tag');

done_testing;
