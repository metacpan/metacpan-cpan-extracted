package PAX::AppImage;

our $VERSION = '0.031';

use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Find ();
use File::Path qw(make_path);
use File::Spec;
use JSON::PP qw(decode_json);

# new(%args)
# Constructs the app-image manager rooted at the directory where named app
# images should be written and reloaded later.
# Input: optional root path.
# Output: PAX::AppImage object.
sub new {
    my ($class, %args) = @_;
    return bless {
        root => $args{root} // $ENV{PAX_APP_ROOT} // '.pax/apps',
    }, $class;
}

# build(%args)
# Builds one persistent app-image directory, discovers preload modules and
# assets, writes image metadata, and attempts to compile the C launcher.
# Input: entrypoint, optional name, lib dirs, assets, and asset dirs.
# Output: hash reference describing the built image and config path.
sub build {
    my ($self, %args) = @_;
    my $entrypoint = $args{entrypoint} // die 'entrypoint required';
    my $name = $args{name} // _default_name($entrypoint);
    my @lib_dirs = map { abs_path($_) || $_ } @{ $args{lib_dirs} // [] };
    my $assets = _asset_manifest($args{assets} // [], $args{asset_dirs} // []);
    my $abs_entrypoint = abs_path($entrypoint) || die "entrypoint not found: $entrypoint";
    my $app_dir = File::Spec->catdir($self->{root}, $name);
    make_path($app_dir);

    my $preload = _discover_preload_modules($abs_entrypoint, \@lib_dirs);
    my $socket_path = File::Spec->catfile($app_dir, 'pax-app.sock');
    my $launcher_path = File::Spec->catfile($app_dir, $name);
    my $image = {
        name => $name,
        entrypoint => $abs_entrypoint,
        app_dir => $app_dir,
        socket_path => $socket_path,
        lib_dirs => \@lib_dirs,
        assets => $assets,
        asset_count => scalar(@$assets),
        asset_bytes => _asset_bytes($assets),
        preload_modules => $preload,
        source_hash => _source_hash($abs_entrypoint, \@lib_dirs, $assets),
        launcher_path => $launcher_path,
        asset_root => File::Spec->catdir($app_dir, 'embedded-assets'),
        model => 'single_launcher_with_embedded_assets_and_preloaded_fork_server',
    };
    my $config_path = File::Spec->catfile($app_dir, 'image.json');
    _write_json($config_path, $image);
    my $launcher = _compile_launcher($image);
    $image->{launcher_status} = $launcher->{status};
    $image->{launcher_reason} = $launcher->{reason} if $launcher->{reason};
    _write_json($config_path, $image);
    return {
        status => 'built',
        image => $image,
        config_path => $config_path,
    };
}

# load(%args)
# Loads the saved image metadata for one previously built app image.
# Input: image name.
# Output: decoded image configuration hash reference.
sub load {
    my ($self, %args) = @_;
    my $name = $args{name} // die 'name required';
    my $path = File::Spec->catfile($self->{root}, $name, 'image.json');
    open my $fh, '<', $path or die "cannot read app image $path: $!";
    local $/;
    return decode_json(<$fh>);
}

# path_for($name)
# Returns the metadata file path for a named app image under the configured
# app-image root.
# Input: app image name.
# Output: image.json path string.
sub path_for {
    my ($self, $name) = @_;
    return File::Spec->catfile($self->{root}, $name, 'image.json');
}

# _default_name($entrypoint)
# Derives a launcher-safe default image name from the entrypoint filename when
# the caller does not provide an explicit application name.
# Input: entrypoint path.
# Output: sanitized image name.
sub _default_name {
    my ($entrypoint) = @_;
    my ($vol, $dir, $file) = File::Spec->splitpath($entrypoint);
    $file =~ s/[^A-Za-z0-9_.-]+/-/g;
    return $file || 'pax-app';
}

# _discover_preload_modules($entrypoint, $lib_dirs)
# Scans the entrypoint and declared library roots for static use/require
# statements so the app server can preload stable dependencies.
# Input: entrypoint path and library roots.
# Output: array reference of module names.
sub _discover_preload_modules {
    my ($entrypoint, $lib_dirs) = @_;
    my %seen;
    for my $path ($entrypoint, _perl_files($lib_dirs)) {
        my $source = _slurp($path);
        while ($source =~ /^\s*use\s+([A-Za-z_][A-Za-z0-9_:]*)\b/gm) {
            next if $1 =~ /^(?:strict|warnings|utf8|lib|parent|base|constant|feature)$/;
            $seen{$1} = 1;
        }
        while ($source =~ /^\s*require\s+([A-Za-z_][A-Za-z0-9_:]*)\b/gm) {
            $seen{$1} = 1;
        }
    }
    return [sort keys %seen];
}

# _perl_files($lib_dirs)
# Enumerates Perl source files beneath the declared library roots so preload
# discovery and source hashing see the same file set.
# Input: library-root array reference.
# Output: list of Perl file paths.
sub _perl_files {
    my ($lib_dirs) = @_;
    my @files;
    for my $dir (@$lib_dirs) {
        next if !-d $dir;
        File::Find::find({
            wanted => sub {
                return if !-f $_;
                return if $_ !~ /\.(?:pm|pl)$/ && $_ !~ /^[A-Za-z0-9_.-]+$/;
                push @files, $File::Find::name;
            },
            no_chdir => 1,
        }, $dir);
    }
    return @files;
}

# _source_hash($entrypoint, $lib_dirs, $assets)
# Computes the invalidation hash for the app image from source files and
# embedded asset digests.
# Input: entrypoint path, library roots, and asset manifest entries.
# Output: SHA-256 digest string.
sub _source_hash {
    my ($entrypoint, $lib_dirs, $assets) = @_;
    my $sha = Digest::SHA->new(256);
    for my $path ($entrypoint, sort _perl_files($lib_dirs)) {
        next if !-f $path;
        $sha->add($path);
        $sha->add(_slurp($path));
    }
    for my $asset (@{ $assets // [] }) {
        $sha->add($asset->{logical_path});
        $sha->add($asset->{sha256});
    }
    return $sha->hexdigest;
}

# _compile_launcher($image)
# Writes and compiles the small C launcher that fronts an app image and falls
# back to perl execution when the launcher cannot be built.
# Input: image metadata hash reference.
# Output: hash reference with build status and optional reason.
sub _compile_launcher {
    my ($image) = @_;
    my $source_path = "$image->{launcher_path}.c";
    open my $fh, '>', $source_path or return { status => 'not_built', reason => "cannot write launcher source: $!" };
    print {$fh} _launcher_source($image);
    close $fh;
    my $cc = _which('cc') || _which('gcc');
    return { status => 'not_built', reason => 'no C compiler available' } if !$cc;
    system($cc, '-O2', '-o', $image->{launcher_path}, $source_path);
    return (($? >> 8) == 0 && -x $image->{launcher_path})
        ? { status => 'built' }
        : { status => 'not_built', reason => 'C launcher compile failed' };
}

# _launcher_source($image)
# Renders the C source for the app-image launcher, including embedded asset
# extraction and Unix-socket request forwarding.
# Input: image metadata hash reference.
# Output: C source string.
sub _launcher_source {
    my ($image) = @_;
    my $socket = _c_string($image->{socket_path});
    my $entrypoint = _c_string($image->{entrypoint});
    my $perl5lib = _c_string(join ':', @{ $image->{lib_dirs} // [] });
    my $asset_root = _c_string($image->{asset_root});
    my $asset_table = _asset_table_c($image->{assets} // []);
    return <<"C";
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>

struct pax_asset {
    const char *path;
    const unsigned char *data;
    unsigned long len;
};

$asset_table

static void ensure_parent_dirs(const char *path) {
    char tmp[4096];
    size_t len = strlen(path);
    if (len >= sizeof(tmp)) return;
    memcpy(tmp, path, len + 1);
    for (char *p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = 0;
            mkdir(tmp, 0700);
            *p = '/';
        }
    }
}

static void extract_embedded_assets(void) {
    if (pax_asset_count == 0) return;
    mkdir($asset_root, 0700);
    for (unsigned long i = 0; i < pax_asset_count; i++) {
        char path[4096];
        snprintf(path, sizeof(path), "%s/%s", $asset_root, pax_assets[i].path);
        ensure_parent_dirs(path);
        FILE *out = fopen(path, "wb");
        if (!out) continue;
        fwrite(pax_assets[i].data, 1, pax_assets[i].len, out);
        fclose(out);
    }
    setenv("PAX_EMBEDDED_ASSET_ROOT", $asset_root, 1);
}

static void json_string(FILE *out, const char *s) {
    fputc('"', out);
    for (; *s; s++) {
        if (*s == '"' || *s == '\\\\') { fputc('\\\\', out); fputc(*s, out); }
        else if (*s == '\\n') fputs("\\\\n", out);
        else fputc(*s, out);
    }
    fputc('"', out);
}

static int fallback_exec(int argc, char **argv) {
    extract_embedded_assets();
    if (strlen($perl5lib) > 0) {
        const char *old = getenv("PERL5LIB");
        char merged[8192];
        if (old && strlen(old) > 0) snprintf(merged, sizeof(merged), "%s:%s", $perl5lib, old);
        else snprintf(merged, sizeof(merged), "%s", $perl5lib);
        setenv("PERL5LIB", merged, 1);
    }
    char **next = calloc((size_t)argc + 2, sizeof(char *));
    if (!next) return 111;
    next[0] = "perl";
    next[1] = $entrypoint;
    for (int i = 1; i < argc; i++) next[i + 1] = argv[i];
    execvp("perl", next);
    perror("execvp perl");
    return 111;
}

int main(int argc, char **argv) {
    extract_embedded_assets();
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return fallback_exec(argc, argv);
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, $socket, sizeof(addr.sun_path) - 1);
    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) != 0) return fallback_exec(argc, argv);

    FILE *stream = fdopen(fd, "r+");
    if (!stream) return fallback_exec(argc, argv);
    fputs("{\\"argv\\":[", stream);
    for (int i = 1; i < argc; i++) {
        if (i > 1) fputc(',', stream);
        json_string(stream, argv[i]);
    }
    fputs("],\\"cwd\\":", stream);
    char cwd[4096];
    if (getcwd(cwd, sizeof(cwd))) json_string(stream, cwd); else json_string(stream, ".");
    fputs("}\\n", stream);
    fflush(stream);

    char buf[8192];
    while (fgets(buf, sizeof(buf), stream)) {
        if (strncmp(buf, "__PAX_EXIT__:", 13) == 0) return atoi(buf + 13);
        fputs(buf, stdout);
    }
    return 0;
}
C
}

# _asset_manifest($assets, $asset_dirs)
# Normalizes explicit asset files and asset directories into one manifest with
# logical paths, digests, and inline payload bytes.
# Input: asset-file list and asset-directory list.
# Output: array reference of asset manifest entries.
sub _asset_manifest {
    my ($assets, $asset_dirs) = @_;
    my @paths = map { [$_, _logical_name($_)] } @$assets;
    for my $dir (@$asset_dirs) {
        my $abs_dir = abs_path($dir) || next;
        File::Find::find({
            wanted => sub {
                return if !-f $_;
                my $rel = File::Spec->abs2rel($File::Find::name, $abs_dir);
                push @paths, [$File::Find::name, $rel];
            },
            no_chdir => 1,
        }, $abs_dir);
    }

    my @manifest;
    my %seen;
    for my $pair (@paths) {
        my ($path, $logical) = @$pair;
        my $abs = abs_path($path) || next;
        next if $seen{$logical}++;
        my $bytes = _slurp_bytes($abs);
        push @manifest, {
            source_path => $abs,
            logical_path => _safe_logical_path($logical),
            size => length($bytes),
            sha256 => sha256_hex($bytes),
            c_symbol => 'pax_asset_' . sha256_hex($logical),
            bytes => $bytes,
        };
    }
    return \@manifest;
}

# _asset_bytes($assets)
# Sums embedded asset payload sizes for reporting in the image manifest.
# Input: asset manifest array reference.
# Output: total byte count.
sub _asset_bytes {
    my ($assets) = @_;
    my $total = 0;
    $total += $_->{size} for @$assets;
    return $total;
}

# _asset_table_c($assets)
# Emits the C data table that embeds asset payload bytes into the launcher
# source file.
# Input: asset manifest array reference.
# Output: C source fragment string.
sub _asset_table_c {
    my ($assets) = @_;
    return "static const unsigned long pax_asset_count = 0;\nstatic const struct pax_asset pax_assets[] = { {0, 0, 0} };\n" if !@$assets;
    my @chunks;
    for my $asset (@$assets) {
        my $symbol = $asset->{c_symbol};
        my $bytes = join ', ', map { sprintf '0x%02x', ord($_) } split //, $asset->{bytes};
        $bytes = '0' if $bytes eq '';
        push @chunks, "static const unsigned char $symbol\[] = { $bytes };\n";
    }
    push @chunks, "static const unsigned long pax_asset_count = " . scalar(@$assets) . ";\n";
    push @chunks, "static const struct pax_asset pax_assets[] = {\n";
    for my $asset (@$assets) {
        push @chunks, '    { ' . _c_string($asset->{logical_path}) . ", $asset->{c_symbol}, $asset->{size} },\n";
    }
    push @chunks, "};\n";
    return join '', @chunks;
}

# _logical_name($path)
# Returns the trailing filename component used as the logical name for a direct
# asset path.
# Input: file path.
# Output: filename string.
sub _logical_name {
    my ($path) = @_;
    my ($vol, $dir, $file) = File::Spec->splitpath($path);
    return $file;
}

# _safe_logical_path($path)
# Strips unsafe path segments from an asset logical path so embedded assets
# cannot escape the extraction root.
# Input: logical asset path.
# Output: normalized forward-slash path.
sub _safe_logical_path {
    my ($path) = @_;
    my @parts = grep { length && $_ ne '.' && $_ ne '..' } File::Spec->splitdir($path);
    return join '/', @parts;
}

# _c_string($value)
# Escapes a string for emission into generated C source.
# Input: Perl string.
# Output: quoted C string literal.
sub _c_string {
    my ($value) = @_;
    $value =~ s/\\/\\\\/g;
    $value =~ s/"/\\"/g;
    return '"' . $value . '"';
}

# _write_json($path, $data)
# Writes canonical JSON metadata for one image manifest.
# Input: output path and Perl data structure.
# Output: none.
sub _write_json {
    my ($path, $data) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} JSON::PP->new->ascii(1)->canonical(1)->pretty(1)->encode($data);
    close $fh;
}

# _slurp($path)
# Reads a text file completely when source scanning needs the original Perl
# text.
# Input: file path.
# Output: text string, or an empty string when the file cannot be read.
sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or return '';
    local $/;
    return <$fh> // '';
}

# _slurp_bytes($path)
# Reads a binary file completely when embedding launcher asset payloads.
# Input: file path.
# Output: byte string, or an empty string when the file cannot be read.
sub _slurp_bytes {
    my ($path) = @_;
    open my $fh, '<:raw', $path or return '';
    local $/;
    return <$fh> // '';
}

# _which($cmd)
# Resolves an executable name through PATH for the launcher compile toolchain
# lookup.
# Input: command name.
# Output: executable path or undef.
sub _which {
    my ($cmd) = @_;
    for my $dir (split /:/, $ENV{PATH} // '') {
        my $path = "$dir/$cmd";
        return $path if -x $path;
    }
    return;
}

1;

=pod

=head1 NAME

PAX::AppImage - application image builder and launcher packager

=head1 SYNOPSIS

  use PAX::AppImage;

  my $images = PAX::AppImage->new(root => '.pax/apps');
  my $built = $images->build(
      entrypoint => 'bin/app.pl',
      name       => 'my-app',
      lib_dirs   => ['lib'],
      asset_dirs => ['share'],
  );

  my $image = $images->load(name => 'my-app');

=head1 DESCRIPTION

This module builds the persistent app-image layout that PAX uses for packaged
applications which keep a named runtime directory instead of collapsing into a
single standalone binary.

An app image contains the normalized image metadata, a compiled launcher, the
Unix-socket location used by the app server, preload-module hints, and the
embedded asset payload list. The launcher it generates can either talk to the
running app server or fall back to launching the Perl entrypoint directly when
the server socket is not available.

=head1 METHODS

=head2 new, build, load, path_for

Use C<new> to choose the root that stores named app images, C<build> to write
or refresh one image, C<load> to inspect saved metadata, and C<path_for> to
locate the image manifest on disk.

=head1 PURPOSE

This module keeps the app-image model in one place so the CLI, packaging code,
and runtime server agree on how named packaged applications are laid out.

=head1 WHY IT EXISTS

PAX supports both single-binary standalone packaging and named application
images. The application-image path needs launcher generation, embedded asset
tracking, and preload discovery that do not belong in the generic CLI layer.

=head1 WHEN TO USE

Edit this file when a change affects named app-image layout, launcher source
generation, preload discovery, embedded asset packaging, or the metadata
contract written to C<image.json>.

=head1 HOW TO USE

Call C<build> with an entrypoint, optional application name, and any library or
asset roots that should travel with the packaged application. The resulting
metadata can then be loaded again by name through C<load> or served through the
app-server runtime.

=head1 WHAT USES IT

This module is used by the app-image build commands, the packaged app server,
and the acceptance tests that cover named packaged applications with embedded
assets.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::AppImage -e 'PAX::AppImage->new(root => q(.pax/apps))'

Load the module and construct an image manager from a source checkout.

Example 2:

  prove -lv t/app_image.t

Run the focused regression coverage for named app-image packaging.

=cut
