package NVMPL::Uninstaller;
use strict;
use warnings;
use feature 'say';
use File::Spec;
use File::Path qw(remove_tree);
use NVMPL::Config;
use NVMPL::Switcher;

# ---------------------------------------------------------
# Public entry point
# ---------------------------------------------------------

sub uninstall_version {
    my ($version) = @_;
    
    unless ($version) {
        _exit_with_error("Usage: nvm-pl uninstall <version>");
    }

    $version =~ s/^V//i;

    # Support both with and without 'v' prefix
    my $vtag = $version =~ /^v/i ? $version : "v$version";

    my $cfg = NVMPL::Config->load();
    my $install_dir = $cfg->{install_dir};
    my $versions_dir = File::Spec->catdir($install_dir, 'versions');
    my $target_dir = File::Spec->catdir($versions_dir, $vtag);

    # Check if version exists
    unless (-d $target_dir) {
        die "[nvm-pl] Node.js version $vtag is not installed.\n";
    }

    # Check if this is the currently active version
    my $current_version = NVMPL::Switcher::_get_current_version();
    if ($current_version && $current_version eq $vtag) {
        say "[nvm-pl] Warning: $vtag is currently in use.";
        say "         Switching to default version before uninstall...";
        
        # Try to switch to another installed version
        my $alternative = _find_alternative_version($vtag);
        if ($alternative) {
            NVMPL::Switcher::use_version($alternative);
        } else {
            say "[nvm-pl] No other versions installed. You'll need to manually install another version.";
            
            my $current_link = File::Spec->catfile($versions_dir, 'current');
        if (-l $current_link) {
            unlink $current_link or warn "[nvm-pl] Could not remove broken 'current' symlink: $!";
            say "[nvm-pl] Removed broken 'current' symlink.";
        }
        }
    }

    # Confirm uninstall (optional - you might want to make this configurable)
    unless (_confirm_uninstall($vtag)) {
        say "[nvm-pl] Uninstall cancelled.";
        return;
    }

    # Remove the version directory
    say "[nvm-pl] Removing Node.js $vtag...";
    my $success = remove_tree($target_dir, { error => \my $errors });

    if ($success && !@$errors) {
        say "[nvm-pl] Successfully uninstalled Node.js $vtag";
        
        # Clean up any cached downloads for this version
        _cleanup_cached_downloads($vtag);
        
    } else {
        my $error_msg = join(', ', @$errors);
        die "[nvm-pl] Failed to uninstall $vtag: $error_msg\n";
    }
}

# ---------------------------------------------------------
# Helper methods
# ---------------------------------------------------------

sub _exit_with_error {
    my ($message) = @_;
    say $message;
    exit 1;
}

sub _find_alternative_version {
    my ($exclude_version) = @_;
    
    my $cfg = NVMPL::Config->load();
    my $versions_dir = File::Spec->catdir($cfg->{install_dir}, 'versions');
    
    opendir(my $dh, $versions_dir) or return undef;
    my @versions = grep { 
        /^v\d+\.\d+\.\d+$/ && -d File::Spec->catdir($versions_dir, $_) && $_ ne $exclude_version 
    } readdir($dh);
    closedir($dh);
    
    # Sort versions and return the highest one
    @versions = sort { _compare_versions($b, $a) } @versions;
    return $versions[0] if @versions;
    
    return undef;
}

sub _compare_versions {
    my ($a, $b) = @_;
    
    # Remove 'v' prefix for comparison
    $a =~ s/^v//i;
    $b =~ s/^v//i;
    
    my @a_parts = split(/\./, $a);
    my @b_parts = split(/\./, $b);
    
    for my $i (0..2) {
        my $a_val = $a_parts[$i] || 0;
        my $b_val = $b_parts[$i] || 0;
        return $a_val <=> $b_val if $a_val != $b_val;
    }
    
    return 0;
}

sub _confirm_uninstall {
    my ($version) = @_;
    
    # You might want to make this configurable via NVMPL::Config
    # For now, we'll always ask for confirmation
    
    print "[nvm-pl] Are you sure you want to uninstall Node.js $version? [y/N] ";
    my $response = <STDIN>;
    chomp $response;
    
    return $response =~ /^y(es)?$/i;
}

sub _cleanup_cached_downloads {
    my ($version) = @_;
    
    my $cfg = NVMPL::Config->load();
    my $downloads_dir = File::Spec->catdir($cfg->{install_dir}, 'downloads');
    
    # Look for download files matching this version
    opendir(my $dh, $downloads_dir) or return;
    my @matching_files = grep { /node-$version-/ } readdir($dh);
    closedir($dh);
    
    foreach my $file (@matching_files) {
        my $file_path = File::Spec->catfile($downloads_dir, $file);
        if (-f $file_path) {
            unlink $file_path or warn "[nvm-pl] Warning: Could not remove cached file $file_path: $!\n";
            say "[nvm-pl] Removed cached download: $file";
        }
    }
}

# ---------------------------------------------------------
# Batch uninstall - optional feature
# ---------------------------------------------------------

sub uninstall_multiple {
    my (@versions) = @_;
    
    unless (@versions) {
        say "Usage: nvm-pl uninstall <version1> [version2 ...]";
        exit 1;
    }
    
    my @successful = ();
    my @failed = ();
    
    foreach my $version (@versions) {
        eval {
            uninstall_version($version);
            push @successful, $version;
        };
        if ($@) {
            warn "[nvm-pl] Failed to uninstall $version: $@";
            push @failed, $version;
        }
    }
    
    if (@successful) {
        say "[nvm-pl] Successfully uninstalled: " . join(', ', @successful);
    }
    
    if (@failed) {
        say "[nvm-pl] Failed to uninstall: " . join(', ', @failed);
        exit 1;
    }
}

1;