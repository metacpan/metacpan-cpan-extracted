#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::File 'path';
use File::Temp 'tempdir';
use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../../Mojolicious-Plugin-Fondation/lib";

use Mojolicious::Plugin::Fondation::TestHelper qw(create_fondation_app capture_command);

use_ok 'Mojolicious::Plugin::Fondation::Asset';

my $SHARE_DIR = "$FindBin::Bin/share/fondation/test_asset";

# ═══════════════════════════════════════════════════════════════════════════
# Helper: build a fresh app (no pre-generated def)
# ═══════════════════════════════════════════════════════════════════════════

sub build_app {
    my $tmpdir = tempdir(CLEANUP => 1);
    return create_fondation_app($tmpdir, {
        dependencies => [
            {'Fondation::Asset'     => {}},
            {'Fondation::TestAsset' => { share_dir => $SHARE_DIR }},
        ],
    });
}

# ═══════════════════════════════════════════════════════════════════════════
# Helper: build app + run generate, returns the app
# ═══════════════════════════════════════════════════════════════════════════

sub build_app_with_def {
    my $app = build_app;
    capture_command($app, 'asset', 'generate', '-y');
    return $app;
}

# ═══════════════════════════════════════════════════════════════════════════
# Helper: create a new app reusing a home dir (so it finds the generated def)
# ═══════════════════════════════════════════════════════════════════════════

sub app_from_home {
    my ($home, %extra) = @_;

    my $app = Mojolicious->new;
    $app->log->level('fatal');
    $app->home($home);
    $app->mode('development') if $extra{dev};

    $app->plugin('Fondation' => {
        dependencies => [
            {'Fondation::Asset'     => {}},
            {'Fondation::TestAsset' => { share_dir => $SHARE_DIR }},
        ],
    });

    return $app;
}

# ═══════════════════════════════════════════════════════════════════════════
# 1. No assetpack.def → warning, no crash, no asset helper
# ═══════════════════════════════════════════════════════════════════════════

subtest 'No assetpack.def: warns but does not crash' => sub {
    my $app = build_app;

    ok($app->manager, 'Fondation manager still accessible');
    ok(!$app->renderer->helpers->{asset}, 'asset helper NOT registered without def');
    ok(!eval { $app->asset; 1 }, 'calling $app->asset fails without AssetPack loaded');
};

# ═══════════════════════════════════════════════════════════════════════════
# 2. With assetpack.def → AssetPack loaded, topics registered
# ═══════════════════════════════════════════════════════════════════════════

subtest 'With assetpack.def: AssetPack loaded at startup' => sub {
    my $app1 = build_app_with_def;
    my $app2 = app_from_home($app1->home);

    ok($app2->renderer->helpers->{asset}, 'asset helper registered');

    my $assets = $app2->asset->processed('app.css');
    ok($assets, 'app.css topic registered at runtime');
    cmp_ok($assets->size, '>=', 1, 'app.css has assets');
};

# ═══════════════════════════════════════════════════════════════════════════
# 3. store->paths contains plugin public dirs
# ═══════════════════════════════════════════════════════════════════════════

subtest 'store->paths includes plugin public directories' => sub {
    my $app1 = build_app_with_def;
    my $app2 = app_from_home($app1->home);

    my @paths  = @{ $app2->asset->store->paths };
    my @public = grep { /test_asset\/public/ } @paths;
    ok(@public > 0, 'TestAsset public dir in store paths');
};

# ═══════════════════════════════════════════════════════════════════════════
# 4. Template renders asset tags in dev mode
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Template renders asset tag in dev mode' => sub {
    my $app1 = build_app_with_def;
    my $app2 = app_from_home($app1->home, dev => 1);

    $app2->routes->get('/test' => sub {
        my $c = shift;
        $c->render(text => $c->asset('app.css'));
    });

    my $t = Test::Mojo->new($app2);
    $t->get_ok('/test')
      ->status_is(200);

    my $body = $t->tx->res->body;
    like($body, qr{test-local\.css}, 'local asset rendered in dev mode');
    like($body, qr{<link.*rel="stylesheet"}, 'link tag present for CSS');
};

done_testing;
