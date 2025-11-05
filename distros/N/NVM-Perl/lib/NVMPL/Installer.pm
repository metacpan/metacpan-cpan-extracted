package NVMPL::Installer;
use strict;
use warnings;
use feature 'say';
use HTTP::Tiny;
use File::Spec;
use File::Path qw(make_path);
use Archive::Zip;
use NVMPL::Config;
use NVMPL::Utils qw(detect_platform);

# ---------------------------------------------------------
# Public entry point
# ---------------------------------------------------------

sub install_version {
    my ($version) = @_;
    unless ($version) {
        say "Usage: nvm-pl install <version>";
        exit 1;
    }

    $version =~ s/^V//i;

    unless ($version =~ /^\d+\.\d+\.\d+$/) {
        die "Invalid version format. Use X.Y.Z (e.g., 22.3.0)\n";
    }
    
    my $vtag = "v$version";

    my $cfg = NVMPL::Config->load();
    my $mirror = $cfg->{mirror_url};
    my $install_dir = $cfg->{install_dir};
    my $downloads = File::Spec->catdir($install_dir, 'downloads');
    my $versions = File::Spec->catdir($install_dir, 'versions');

    my $platform = detect_platform();
    my $os = _map_platform_to_node_os($platform);
    my $arch = _detect_arch();
    my $ext = $platform eq 'windows' ? 'zip' : 'tar.xz';

    make_path($downloads) unless -d $downloads;
    make_path($versions) unless -d $versions;

    my $filename = "node-$vtag-$os-$arch.$ext";
    my $download_path = File::Spec->catfile($downloads, $filename);
    my $target_dir = File::Spec->catdir($versions, $vtag);

    if (-d $target_dir) {
        say "[nvm-pl] Node $vtag already installed.";
        return;
    }

    my $url = "$mirror/$vtag/$filename";
    say "[nvm-pl] Fetching: $url";

    unless (-f $download_path) {
        my $ua = HTTP::Tiny->new;
        my $resp = _download_file($url, $download_path);
        die "Download failed: $resp->{status} $resp->{reason}\n"
            unless $resp->{success};
        say "[nvm-pl] Saved to $download_path";
    } else {
        say "[nvm-pl] Using cached file: $download_path";
    }

    say "[nvm-pl] Extracting to $target_dir";
    make_path($target_dir);

    if ($ext eq 'zip') {
        my $zip = Archive::Zip->new();
        $zip->read($download_path) == 0 or die "Failed to read zip\n";
        $zip->extractTree('', "$target_dir/");
    } else {
        _should_extract_with_tar($download_path, $target_dir);
    }

    say "[nvm-pl] Node $vtag installed successfully.";
}

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------

sub _detect_arch {
    my $arch = `uname -m 2>/dev/null` || $ENV{PROCESSOR_ARCHITECTURE} || 'x64';
    chomp $arch;
    return 'x64' if $arch =~ /x86_64|amd64/i;
    return 'arm64' if $arch =~ /arm64|aarch64/i;
    return 'x86' if $arch =~ /i[3456]86/;
    return $arch;
}

sub _map_platform_to_node_os {
    my ($platform) = @_;
    my %map = (
        windows => 'win',
        macos   => 'darwin',
        linux   => 'linux',
    );
    return $map{$platform} || $platform;
}

sub _should_extract_with_tar {
    my ($download_path, $target_dir) = @_;
    system("tar", "xf", $download_path, "-C", $target_dir, "--strip-components=1") == 0
        or die "Extraction failed: $?";
}

sub _download_file {
    my ($url, $path) = @_;
    my $ua = HTTP::Tiny->new;
    return $ua->mirror($url, $path);
}

1;