use strict;
use warnings;
use Test::More;
use File::Path qw(remove_tree);
use FindBin;
use JSON::PP ();
use lib "$FindBin::Bin/../lib";

use PAX::AppImage;
use PAX::AppServer;
use PAX::Paxfile;

=pod

=head1 NAME

t/app_image.t - internal app image subsystem tests

=head1 DESCRIPTION

SOW-03 removes app-image commands from the public C<bin/pax> surface. This file
keeps coverage for the reusable app image and app server modules through direct
Perl APIs.

=cut

my $root = "$FindBin::Bin/tmp-apps";
remove_tree($root) if -d $root;
local $ENV{PAX_APP_ROOT} = $root;

my $builder = PAX::AppImage->new(root => $root);
my $built = $builder->build(
    name => 'fixture-app',
    entrypoint => "$FindBin::Bin/fixtures/app_entry.pl",
    lib_dirs => ["$FindBin::Bin/fixtures/app_lib"],
    assets => ["$FindBin::Bin/fixtures/app_assets/banner.txt"],
);

is($built->{status}, 'built', 'app image built');
ok(-f $built->{config_path}, 'image config written');
ok(-x $built->{image}{launcher_path}, 'native launcher built');
ok(grep { $_ eq 'SlowLoad' } @{ $built->{image}{preload_modules} }, 'preload module discovered');
is($built->{image}{asset_count}, 1, 'asset is embedded into image metadata');
is($built->{image}{assets}[0]{logical_path}, 'banner.txt', 'asset logical path is recorded');

my $image = $builder->load(name => 'fixture-app');
my $pid = fork();
die "fork failed: $!" if !defined $pid;
if ($pid == 0) {
    PAX::AppServer->new(image => $image)->start;
    exit 0;
}

for (1..50) {
    last if -S $image->{socket_path};
    select undef, undef, undef, 0.05;
}
ok(-S $image->{socket_path}, 'app server socket is ready');

my $client_status = PAX::AppServer->run_client(image => $image, argv => ['status']);
is($client_status, 0, 'app server client exits successfully through module API');

my $launcher_output = `$image->{launcher_path} status`;
is($? >> 8, 0, 'native launcher exits successfully');
is($launcher_output, "slowload-ready\n", 'native launcher dispatches through app server');
ok(-f "$image->{asset_root}/banner.txt", 'native launcher extracts embedded asset');
my $asset_text = do {
    open my $fh, '<', "$image->{asset_root}/banner.txt" or die $!;
    local $/;
    <$fh>;
};
is($asset_text, "embedded-fixture-asset\n", 'extracted asset content matches source');

PAX::AppServer->stop(image => $image);
waitpid($pid, 0);

my $paxfile = PAX::Paxfile->load("$FindBin::Bin/fixtures/paxfile.yml");
is($paxfile->{name}, 'fixture-app', 'paxfile scalar name parsed');
is_deeply($paxfile->{libs}, ['t/fixtures/app_lib'], 'paxfile repeatable libs parsed');

remove_tree($root) if -d $root;
my $paxfile_build = PAX::AppImage->new(root => $root)->build(
    name => $paxfile->{name},
    entrypoint => "$FindBin::Bin/fixtures/app_entry.pl",
    lib_dirs => ["$FindBin::Bin/fixtures/app_lib"],
    assets => ["$FindBin::Bin/fixtures/app_assets/banner.txt"],
);
is($paxfile_build->{status}, 'built', 'app image builder reads paxfile-equivalent defaults through module API');
is($paxfile_build->{image}{asset_count}, 1, 'paxfile asset embedded');
ok(-x $paxfile_build->{image}{launcher_path}, 'paxfile build creates launcher');

my $override_build = PAX::AppImage->new(root => $root)->build(
    name => 'override-app',
    entrypoint => "$FindBin::Bin/fixtures/app_entry.pl",
    assets => ["$FindBin::Bin/fixtures/app_assets/banner.txt"],
);
is($override_build->{status}, 'built', 'module API accepts override values without public app-build CLI');
is($override_build->{image}{name}, 'override-app', 'builder name overrides paxfile name');
is($override_build->{image}{entrypoint}, "$FindBin::Bin/fixtures/app_entry.pl", 'builder entrypoint overrides paxfile entrypoint');

remove_tree($root) if -d $root;
done_testing;

=head1 TEST PLAN

This test covers named app-image metadata, launcher fallback behavior, embedded
asset extraction, and module-driven app-image builds.

=head1 HOW TO RUN

  prove -lv t/app_image.t
