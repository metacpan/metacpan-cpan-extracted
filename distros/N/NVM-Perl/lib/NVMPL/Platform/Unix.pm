package NVMPL::Platform::Unix;
use strict;
use warnings;
use feature 'say';
use File::Spec;
use File::Path qw(make_path remove_tree);
use File::Copy qw(move);
use NVMPL::Utils qw(log_info log_warn log_error);

# ---------------------------------------------------------
# Create a symlink safely
# ---------------------------------------------------------

sub create_symlink {
    my ($target, $link) = @_;

    if (-l $link || -e $link) {
        unlink $link or log_warn("Could not remove existing link $link: $!");
    }

    symlink($target, $link)
        or log_error("Failed to create symlink: $!") and return 0;

    log_info("Created symlink: $link -> $target");
    return 1;
}

# ---------------------------------------------------------
# Remove a version directory safely
# ---------------------------------------------------------

sub remove_version_dir {
    my ($dir) = @_;
    if (-d $dir) {
        remove_tree($dir, { safe => 1 });
        log_info("Removed directory: $dir");
        return 1;
    } else {
        log_warn("Directory not found: $dir");
    }
}

# ---------------------------------------------------------
# Extract a .tar.xz archive into target directory
# ---------------------------------------------------------

sub extract_tarball {
    my ($archive, $target_dir) = @_;

    log_info("Extracting $archive to $target_dir");
    make_path($target_dir) unless -d $target_dir;

    my $cmd = "tar -xJf '$archive' -C '$target_dir'";
    system($cmd) == 0
        or die "Extraction failed: $!";

    opendir(my $dh, $target_dir) or return;
    my @subdirs = grep { /^node-v/ && -d "$target_dir/$_" } readdir($dh);
    closedir $dh;

    if (@subdirs == 1) {
        my $inner = File::Spec->catdir($target_dir, $subdirs[0]);
        system("mv '$inner'/& '$target_dir'/") == 0
            or log_warn("could not flatten directory $inner");
        remove_tree($inner, { safe => 1 });
    }
    log_info("Extraction complete");
}


# ---------------------------------------------------------
# Get Node binary path for current version
# ---------------------------------------------------------

sub node_bin_path {
    my ($base_install_dir) = @_;
    return File::Spec->catfile($base_install_dir, 'versions', 'current', 'bin');
}

# ---------------------------------------------------------
# Update PATH for current shell (prints export command)
# ---------------------------------------------------------

sub export_path_snippet {
    my ($base_install_dir) = @_;
    my $bin = node_bin_path($base_install_dir);
    say "export PATH=\"$bin:\$PATH\"";
}

1;