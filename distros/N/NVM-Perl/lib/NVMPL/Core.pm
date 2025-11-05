package NVMPL::Core;
use strict;
use warnings;
use feature 'say';
use NVMPL::Config;
use NVMPL::Installer;
use NVMPL::Uninstaller;
use NVMPL::Switcher;
use NVMPL::Remote;

=head1 NAME

NVMPL::Core - Core dispatch module for nvm-pl Node.js version manager

=head1 VERSION

Version 0.1.1

=head1 SYNOPSIS

    use NVMPL::Core;
    NVMPL::Core::dispatch('install', '25.1.0');

=head1 DESCRIPTION

Core command dispatcher for nvm-pl, a Perl-based Node.js version manager.

=head1 METHODS

=head2 dispatch

    NVMPL::Core::dispatch($command, @args);

Dispatch commands to appropriate modules.

=cut

our $VERSION = '0.1.1';
my $CONFIG;

# ---------------------------------------------------------
# Entry point called from bin/nvm-pl
# ---------------------------------------------------------

sub dispatch {
    my ($command, @args) = @_;

    $CONFIG ||= NVMPL::Config->load();

    unless ($command) {
        say "No command provided. Try 'nvm-pl --help'";
        exit 1;
    }

    # Super Slick
    $command =~ s/-/_/g;

    my %commands = (
        install     => \&_install,
        use         => \&_use,
        ls          => \&_ls,
        ls_remote   => \&_ls_remote,
        current     => \&_current,
        uninstall   => \&_uninstall,
        cache       => \&_cache,
    );

    if (exists $commands{$command}) {
        $commands{$command}->(@args);
    } else {
        say "Unknown command '$command' . Try 'nvm-pl --help'";
        exit 1;
    }
}

# ---------------------------------------------------------
# Command stubs (we'll implement these later)
# ---------------------------------------------------------

sub _install {
    my ($ver) = @_;
    NVMPL::Installer::install_version($ver);
}

sub _use {
    my ($ver) = @_;
    NVMPL::Switcher::use_version($ver);
}

sub _ls {
    NVMPL::Switcher::list_installed();
}

sub _ls_remote {
    my @args = @_;
    my $filter = grep { $_ eq '--lts' } @args ? 1 : 0;
    NVMPL::Remote::list_remote_versions(lts => $filter);
}

sub _current {
    NVMPL::Switcher::show_current();
}

sub _uninstall {
    my ($ver) = @_;
    NVMPL::Uninstaller::uninstall_version($ver);
}

sub _cache {
    my ($subcmd) = @_;
    say "[nvm-pl] Cache command: $subcmd (stub)";
}

1;