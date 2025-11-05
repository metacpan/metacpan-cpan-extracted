package NVMPL::Platform::Windows;
use strict;
use warnings;
use feature 'say';
use File::Spec;
use File::Path qw(make_path remove_tree);
use File::Copy qw(move);
use Archive::Zip qw(AZ_OK);
use NVMPL::Utils qw(log_info log_warn log_error);

# ---------------------------------------------------------
# Create a directory junction (mklink /J)
# ---------------------------------------------------------

sub create_junction {
    my ($target, $link) = @_;

    if (-e $link || -l $link) {
        unlink $link or log_warn("Could not remove existing link: $!");
    }

    my $cmd = qq(cmd /C mklink /J "$link" "$target");
    system($cmd) == 0
        or log_error("Failed to create junction: $!") and return 0;
    
    log_info("Created junction: $link -> $target");
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
        return 0;
    }
}

# ---------------------------------------------------------
# Extract a .zip archive into target directory
# ---------------------------------------------------------

sub extract_zip {
    my ($archive, $target_dir) = @_;

    log_info("Extracting $archive to $target_dir");
    make_path($target_dir) unless -d $target_dir;

    my $zip = Archive::Zip->new();
    my $status = $zip->read($archive);
    if ($status != AZ_OK) {
        log_error("Failed to read zip file: $archive");
        return 0;
    }

    my $ok = $zip->extractTree('', "$target_dir//");
    unless ($ok == AZ_OK) {
        log_error("Failed to extract zip file to $target_dir");
        return 0;
    }

    opendir(my $dh, $target_dir) or return 1;
    my @subdirs = grep { /^node-v/ && -d "$target_dir//$_" } readdir($dh);
    closedir $dh;

    if (@subdirs == 1) {
        my $inner = "$target_dir//$subdirs[0]";
        system("xcopy \"$inner\" \"$target_dir\" /E /I /Y >NUL") == 0
            or log_warn("Could not flatten directory: $inner");
        remove_tree($inner, { safe => 1 });
    }
    log_info("Extraction complete");
    return 1;
}

# ---------------------------------------------------------
# Get Node binary path for current version
# ---------------------------------------------------------

sub node_bin_path {
    my ($base_install_dir) = @_;
    return File::Spec->catfile($base_install_dir, 'versions', 'current', 'bin');
}

# ---------------------------------------------------------
# Print PowerShell snippet to set PATH
# ---------------------------------------------------------

sub export_path_snippet {
    my ($base_install_dir) = @_;
    my $bin = node_bin_path($base_install_dir);
    say 'To use this Node version in PowerShell, run:';
    say " \$Env:PATH = \"$bin;\" + \$Env:PATH";
    say '';
    say 'Or in cmd.exe, run:';
    say " set PATH=$bin;%PATH%";
}

1;