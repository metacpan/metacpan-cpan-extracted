package NVMPL::Switcher;
use strict;
use warnings;
use feature 'say';
use File::Spec;
use NVMPL::Config;
use NVMPL::Utils qw(detect_platform);

# ---------------------------------------------------------
# Public entry point
# ---------------------------------------------------------

sub _detect_shell {
    # --- Windows shell detection first ---
    if ($^O eq 'MSWin32') {
        # PowerShell defines PSModulePath, CMD defines ComSpec
        if ($ENV{PSModulePath}) {
            return 'PowerShell';
        } elsif ($ENV{ComSpec} && $ENV{ComSpec} =~ /cmd\.exe/i) {
            return 'Cmd';
        } else {
            return 'PowerShell';  # safe default on Windows
        }
    }

    # --- Unix-like environments ---
    my $shell = $ENV{SHELL} || '';
    if ($shell =~ /zsh/i) {
        return 'Zsh';
    } elsif ($shell =~ /bash/i) {
        return 'Bash';
    } else {
        return 'Bash';  # fallback for unknown shells
    }
}

sub use_version {
    my ($version) = @_;
    unless ($version) {
        say "Usage: nvm-pl use <version>";
        return 1;
    }

    $version =~ s/^V//;
    my $vtag = "v$version";

    my $cfg = NVMPL::Config->load();
    my $install_dir  = $cfg->{install_dir};
    my $versions_dir = File::Spec->catdir($install_dir, 'versions');
    my $target_dir   = File::Spec->catdir($versions_dir, $vtag);

    # --- Windows nested node folder fix ---
    if ($^O eq 'MSWin32') {
        my @matches = glob("$target_dir\\node-v*-win-x64");
        if (@matches && -d $matches[0]) {
            $target_dir = $matches[0];
        }
    }

    my $current_link = File::Spec->catfile($versions_dir, 'current');

    unless (-d $target_dir) {
        say "[nvm-pl] Version $vtag is not installed.";
        return 1;
    }

    if (-l $current_link || -d $current_link) {
        unlink $current_link or warn "[nvm-pl] Could not remove existing 'current': $!";
    }

    if ($^O =~ /MSWin/) {
        _win_junction($current_link, $target_dir);
    } else {
        symlink($target_dir, $current_link)
            or die "[nvm-pl] Failed to create symlink: $!";
    }

    _update_shell_config($current_link);

    say "[nvm-pl] Active version is now $vtag";

    # --- PowerShell live PATH update ---
    if ($^O eq 'MSWin32' && $ENV{PSModulePath}) {
        my $ps_path = $target_dir;
        $ps_path =~ s#/#\\#g;

        # only update if node.exe isn't already on PATH
        my $node_check = `where node 2> NUL`;
        if ($node_check !~ /\Q$ps_path\E/i) {
            # Detect which PowerShell to use
            my $ps_exe = `where pwsh 2> NUL`;
            chomp($ps_exe);
            if (!$ps_exe) {
                $ps_exe = `where powershell 2> NUL`;
                chomp($ps_exe);
            }

            if ($ps_exe) {
                say "[nvm-pl] (PowerShell) Updating PATH for current session...";
                system($ps_exe, "-NoLogo", "-NoProfile", "-Command",
                    "\$env:PATH = '$ps_path;' + \$env:PATH; Write-Host 'PATH updated for this session.'");
            } else {
                say "[nvm-pl] (PowerShell) Could not find PowerShell executable — skipping live PATH update.";
            }
        } else {
            say "[nvm-pl] (PowerShell) Node path already active.";
        }
    }

    say "Restart your shell or run the appropriate source command for your shell.";
    return 0;
}


sub _update_shell_config {
    my ($current_link) = @_;
    my $shell_type = _detect_shell();

    # Load the appropriate shell module dynamically
    my $shell_module = "NVMPL::Shell::$shell_type";
    eval "require $shell_module" or do {
        warn "[nvm-pl] Could not load $shell_module: $@";
        return;
    };

    my $init_snippet = $shell_module->init_snippet();
    my $config_file  = _get_shell_config($shell_type);
    _write_shell_config($config_file, $init_snippet, $shell_type);
}

sub _get_shell_config {
    my ($shell_type) = @_;
    my $home = $ENV{HOME} // $ENV{USERPROFILE};

    return {
        Bash       => "$home/.bashrc",
        Zsh        => "$home/.zshrc",
        Cmd        => "$home/.cmdrc",
        PowerShell => "$home/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1"
    }->{$shell_type} || "$home/.bashrc";
}

sub _write_shell_config {
    my ($config_file, $init_snippet, $shell_type) = @_;
    return unless $config_file;

    # Read existing config
    my @lines;
    if (-f $config_file) {
        open my $in, '<', $config_file or return;
        @lines = <$in>;
        close $in;
    }

    # Remove ONLY the nvm-pl managed section (more precise)
    my @clean_lines;
    my $in_nvm_section = 0;

    foreach my $line (@lines) {
        # Detect start of nvm-pl section
        if ($line =~ /^# nvm-pl managed Node\.js path$/) {
            $in_nvm_section = 1;
            next;
        }

        # Skip lines until we're out of the nvm-pl section
        if ($in_nvm_section) {
            if ($line =~ /^\s*$/ || $line =~ /^#/) {
                $in_nvm_section = 0;
            } else {
                next;
            }
        }

        push @clean_lines, $line unless $in_nvm_section;
    }

    # Write new config with nvm-pl snippet at the end
    open my $out, '>', $config_file or return;
    print $out @clean_lines;
    print $out "\n# nvm-pl managed Node.js path\n";
    print $out "$init_snippet\n";
    close $out;

    say "[nvm-pl] Updated $config_file for $shell_type";
}

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------

sub _win_junction {
    my ($link, $target) = @_;
    $link   =~ s#/#\\#g;
    $target =~ s#/#\\#g;
    my $cmd = "cmd /C mklink /J \"$link\" \"$target\"";
    system($cmd) == 0
        or die "[nvm-pl] Failed to create junction: $!";
}

sub list_installed {
    my $cfg = NVMPL::Config->load();
    my $versions_dir = File::Spec->catdir($cfg->{install_dir}, 'versions');

    opendir(my $dh, $versions_dir) or die "Can't open $versions_dir: $!";
    my @dirs = grep { /^v\d/ && -d File::Spec->catdir($versions_dir, $_) } readdir($dh);
    closedir $dh;

    if (@dirs) {
        say "[nvm-pl] Installed versions:";
        say " $_" for sort @dirs;
    } else {
        say "[nvm-pl] No versions installed.";
    }
}

sub show_current {
    my $cfg = NVMPL::Config->load();
    my $current = File::Spec->catfile($cfg->{install_dir}, 'versions', 'current');
    if (-l $current) {
        my $target = readlink($current);
        say "[nvm-pl] Current version -> $target";
    } else {
        say "[nvm-pl] No active Node version.";
    }
}

sub _get_current_version {
    my $cfg = NVMPL::Config->load();
    my $current = File::Spec->catfile($cfg->{install_dir}, 'versions', 'current');
    if (-l $current) {
        my $target = readlink($current);
        return (split('/', $target))[-1];
    }
    return undef;
}

1;
