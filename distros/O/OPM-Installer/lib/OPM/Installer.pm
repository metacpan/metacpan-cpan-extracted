package OPM::Installer;

# ABSTRACT: Install ticketsystem (Znuny/OTOBO) add ons

use v5.24;

use strict;
use warnings;

our $VERSION = '1.0.1'; # VERSION

use Moo;
use Capture::Tiny qw(:all);
use IO::All;
use Module::Runtime qw(use_module is_module_name);
use Types::Standard qw(ArrayRef Str Bool);

use OPM::Parser;

use OPM::Installer::Utils::TS;
use OPM::Installer::Utils::File;
use OPM::Installer::Logger;

has package      => ( is => 'ro', isa => Str );
has version      => ( is => 'ro', isa => Str, lazy => 1, default => \&_build_version );
has prove        => ( is => 'ro', default => sub { 0 } );
has manager      => ( is => 'ro', lazy => 1, default => \&_build_manager );
has repositories => ( is => 'ro', isa => ArrayRef[Str] );
has conf         => ( is => 'ro' );
has force        => ( is => 'ro', isa => Bool );
has sudo         => ( is => 'ro', isa => Bool );
has utils_ts     => ( is => 'ro', lazy => 1, default => sub{ OPM::Installer::Utils::TS->new } );
has verbose      => ( is => 'ro', isa => Bool, default => sub { 0 } );
has logger       => ( is => 'ro', lazy => 1, default => sub { OPM::Installer::Logger->new } );

sub list_available {
    my ( $self, %params ) = @_;

    my %file_opts;
    if ( $params{repositories} and ref $params{repositories} eq 'ARRAY' ) {
        $file_opts{repositories} = $params{repositories};
    }

    my $package_utils = OPM::Installer::Utils::File->new(
        %file_opts,
        package => 'DummyPackage',   # ::File needs a package set
        version => $self->version,
    );

    return $package_utils->list_available;
}

sub install {
    my $self = shift;

    if ( @_ % 2 ) {
        unshift @_, 'package';
    }

    my %params = @_;

    my %file_opts;
    if ( $self->repositories ) {
        $file_opts{repositories} = $self->repositories;
    }

    if ( $params{repositories} and ref $params{repositories} eq 'ARRAY' ) {
        $file_opts{repositories} = $params{repositories};
    }

    my $version_string = "";
    if ( $params{version} and $params{version_exact} ) {
        $file_opts{version} = $params{version};
        $version_string     = $params{version};
    }

    say sprintf "Try to install %s %s...", $params{package} || $self->package, $version_string if $self->verbose;
   
    my $installed_version = $self->utils_ts->is_installed( package => $params{package} || $self->package );
    if ( $installed_version ) {
        my $message = sprintf 'Addon %s is installed (%s)',
            $params{package} || $self->package, $installed_version;

        $self->logger->debug( message => $message );
        say $message;

        if ( $params{version} ) {
            my $check = $self->utils_ts->_check_version(
                installed => $installed_version,
                requested => $params{version},
            );

            return 1 if $check;
        }
    }

    my $package_utils = OPM::Installer::Utils::File->new(
        %file_opts,
        package           => $params{package} || $self->package,
        framework_version => $self->version,
        verbose           => $self->verbose,
    );

    my $package_path = $package_utils->resolve_path;

    if ( !$package_path ) {
        my $message = sprintf "Could not find a .opm file for %s%s (framework version %s)",
            $params{package} || $self->package,
            ( $file_opts{version} ? " $file_opts{version}" : "" ),
            $self->version;

        $self->logger->error( fatal => $message );
        say $message;
        return;
    }

    my $parsed = OPM::Parser->new(
        opm_file => $package_path,
    );

    $parsed->parse;

    if ( $parsed->error_string ) {
        my $message = sprintf "Cannot parse $package_path: %s", $parsed->error_string;
        $self->logger->error( fatal => $message );
        say $message;
        return;
    }

    if ( !$self->_check_matching_versions( $parsed, $self->version ) ) {
        my $message = sprintf 'framework versions of %s (%s) doesn\'t match ticketsystem version %s',
            $parsed->name,
            join ( ', ', $parsed->framework ),
            $self->version;

        $self->logger->error( fatal => $message );
        say $message;
        return;
    }

    if ( $self->utils_ts->is_installed( package => $parsed->name, version => $parsed->version ) ) {
        my $message = sprintf 'Addon %s is up to date (%s)',
            $parsed->name, $parsed->version;

        $self->logger->debug( message => $message );
        say $message;
        return 1;
    }

    say sprintf "Working on %s...", $parsed->name if $self->verbose;
    $self->logger->debug( message => sprintf "Working on %s...", $parsed->name );

    my @dependencies = @{ $parsed->dependencies || [] };
    my @cpan_deps    = grep{ $_->{type} eq 'CPAN' }@dependencies;
    my @addon_deps   = grep{ $_->{type} eq 'Addon' }@dependencies;

    my $found_dependencies =  join ', ', map{ $_->{name} }@dependencies;
    say sprintf "Found dependencies: %s", $found_dependencies if $self->verbose;
    $self->logger->debug( message => sprintf "Found dependencies: %s", $found_dependencies );

    for my $cpan_dep ( @cpan_deps ) {
        my $module  = $cpan_dep->{name};
        my $version = $cpan_dep->{version};

        next CPANDEP if !is_module_name( $module );

        use_module( $module, $version ) and next;

        $self->_cpan_install( %{$cpan_dep} );
    }

    for my $addon_dep ( @addon_deps ) {
        my $module  = $addon_dep->{name};
        my $version = $addon_dep->{version};

        $self->utils_ts->is_installed( %{$addon_dep} ) and next;

        my $success = $self->install( package => $module, version => $version );
        if ( !$success && !$self->force ) {
            return;
        }
    }

    if ( $self->prove ) {
        # TODO: run unittests
    }

    my $content = io( $package_path )->slurp;

    my $message = sprintf "Install %s ...", $parsed->name;
    say $message if $self->verbose;
    $self->logger->debug( message => $message );

    $self->manager->PackageInstall( String => $content );

    return 1;
}

sub _cpan_install {
    my ( $self, %params) = @_;

    my $dist = $params{name};
    my @sudo = $self->sudo ? 'sudo' : ();
    my ($out, $err, $exit) = capture {
        system @sudo, 'cpanm', $dist;
    };

    if ( $out !~ m{Successfully installed } ) {
        die "Installation of dependency failed ($dist)! - ($err)";
    }

    return;
}

sub _build_manager {
    my $self = shift;

    return $self->utils_ts->manager;
}

sub _build_utils_ts {
    OPM::Installer::Utils::TS->new;
}

sub _build_version {
    shift->utils_ts->framework_version;
}

sub _check_matching_versions {
    my ($self, $parsed, $addon_version) = @_;

    my ($major, $minor, $patch) = split /\./, $addon_version;

    my $check_ok;

    FRAMEWORK:
    for my $required_framework ( @{ $parsed->framework } ) {
        my ($r_major, $r_minor, $r_patch) = split /\./, $required_framework;

        next FRAMEWORK if $r_major != $major;
        next FRAMEWORK if lc $r_minor ne 'x' && $r_minor != $minor;
        next FRAMEWORK if lc $r_patch ne 'x' && $r_patch != $patch;

        $check_ok = 1;
        last FRAMEWORK;
    }

    return $check_ok;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Installer - Install ticketsystem (Znuny/OTOBO) add ons

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

  use OPM::Installer;
  
  my $installer = OPM::Installer->new;
  $installer->install( 'FAQ' );
  
  # or
  
  my $installer = OPM::Installer->new();
  $installer->install( package => 'FAQ', version => '2.1.9' );

  # provide path to a config file
  my $installer = OPM::Installer->new(
      conf => 'test.rc',
  );
  $installer->install( 'FAQ' );

=head1 DESCRIPTION

This is an alternate installer for Znuny/OTOBO addons. The standard package manager
currently does not install dependencies. OPM::Installer takes care of those
dependencies and it can handle dependencies from different places.

=head1 CONFIGURATION FILE

You can provide some basic configuration in a F<.opminstaller.rc> file:

  repository=http://ftp.addon.org/pub/addon/packages
  repository=http://ftp.addon.org/pub/addon/itsm/packages33
  repository=http://opar.perl-services.de
  repository=http://feature-addons.de/repo
  path=/opt/otrs

=head1 ATTRIBUTES

=over 4

=item * conf

=item * force

=item * has

=item * logger

=item * manager

=item * package

=item * prove

=item * repositories

=item * sudo

=item * utils_ts

=item * verbose

=item * version

=back

=head1 ACKNOWLEDGEMENT

The development of this package was sponsored by https://feature-addons.de

=head1 METHODS

=head2 install

=head2 list_available

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
