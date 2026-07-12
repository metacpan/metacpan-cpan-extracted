#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Mojo::File 'path';
use File::Temp 'tempdir';
use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../../Mojolicious-Plugin-Fondation/lib";

use Mojolicious::Plugin::Fondation::TestHelper qw(create_fondation_app capture_command);

use_ok 'Mojolicious::Plugin::Fondation::Asset';

# ═══════════════════════════════════════════════════════════════════════════
# Helper: build app with TestAsset plugin
# ═══════════════════════════════════════════════════════════════════════════

sub build_app {
    my $tmpdir    = tempdir(CLEANUP => 1);
    my $share_dir = "$FindBin::Bin/share/fondation/test_asset";

    return create_fondation_app($tmpdir, {
        dependencies => [
            {'Fondation::Asset'     => {}},
            {'Fondation::TestAsset' => { share_dir => $share_dir }},
        ],
    });
}

# ═══════════════════════════════════════════════════════════════════════════
# 1. Generate creates merged assetpack.def
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Generate creates merged assetpack.def' => sub {
    my $app      = build_app;
    my $out      = capture_command($app, 'asset', 'generate', '-y');
    my $def_file = $app->home->child('share', 'assets', 'assetpack.def');

    ok(-f $def_file, 'assetpack.def created')
        or diag "output: $out";

    like($out, qr/Assets generated successfully/, 'reports success');

    my $def = $def_file->slurp;

    like($def, qr/! app\.css/,            'app.css bundle declared');
    like($def, qr{< css/test-local\.css}, 'local file preserved as <');
};

# ═══════════════════════════════════════════════════════════════════════════
# 2. Topics registered after generate
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Topics registered after generate' => sub {
    my $app   = build_app;
    capture_command($app, 'asset', 'generate', '-y');

    my $asset  = $app->asset;
    ok($asset, 'AssetPack instance exists after generate');

    my $assets = $asset->processed('app.css');
    ok($assets, 'app.css topic registered');
    cmp_ok($assets->size, '>=', 1, 'app.css has at least 1 asset');

    my @local = grep { defined $_->url && $_->url =~ /test-local\.css/ } @$assets;
    is(scalar @local, 1, 'local file included in topic');
};

# ═══════════════════════════════════════════════════════════════════════════
# 3. Idempotent: second generate succeeds
# ═══════════════════════════════════════════════════════════════════════════

subtest 'Second generate is idempotent' => sub {
    my $app   = build_app;
    capture_command($app, 'asset', 'generate', '-y');
    my $out2  = capture_command($app, 'asset', 'generate', '-y');

    like($out2, qr/Assets generated successfully/, 'second generate succeeds');
};

# ═══════════════════════════════════════════════════════════════════════════
# 4. No plugin with assetpack.def → nothing written, no error
# ═══════════════════════════════════════════════════════════════════════════

subtest 'No asset definitions found' => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $app    = create_fondation_app($tmpdir, {
        dependencies => ['Fondation::Asset'],
    });

    my $out = capture_command($app, 'asset', 'generate', '-y');

    like($out, qr/No asset definitions found/, 'reports no definitions');
    ok(!-f $app->home->child('share', 'assets', 'assetpack.def'),
       'no file created when no definitions exist');
};

done_testing;
