package OTRS::OPM::Installer;
$OTRS::OPM::Installer::VERSION = '0.05';
# ABSTRACT: Install OTRS add ons

use v5.10;

use strict;
use warnings;

use Moo;
use IO::All;
use Capture::Tiny qw(:all);
use Types::Standard qw(ArrayRef Str Bool);

use OTRS::OPM::Parser;

use OTRS::OPM::Installer::Types;
use OTRS::OPM::Installer::Utils::OTRS;
use OTRS::OPM::Installer::Utils::File;
use OTRS::OPM::Installer::Logger;

has package      => ( is => 'ro', isa => Str );
has otrs_version => ( is => 'ro', isa => Str, lazy => 1, default => \&_build_otrs_version );
has prove        => ( is => 'ro', default => sub { 0 } );
has manager      => ( is => 'ro', lazy => 1, default => \&_build_manager );
has repositories => ( is => 'ro', isa => ArrayRef[Str] );
has conf         => ( is => 'ro' );
has force        => ( is => 'ro', isa => Bool );
has sudo         => ( is => 'ro', isa => Bool );
has utils_otrs   => ( is => 'ro', lazy => 1, default => sub{ OTRS::OPM::Installer::Utils::OTRS->new } );
has verbose      => ( is => 'ro', isa => Bool, default => sub { 0 } );
has logger       => ( is => 'ro', lazy => 1, default => sub { OTRS::OPM::Installer::Logger->new } );

sub list_available {
    my ( $self, %params ) = @_;

    my %file_opts;
    if ( $params{repositories} and ref $params{repositories} eq 'ARRAY' ) {
        $file_opts{repositories} = $params{repositories};
    }

    my $package_utils = OTRS::OPM::Installer::Utils::File->new(
        %file_opts,
        package      => 'DummyPackage',   # ::File needs a package set
        otrs_version => $self->otrs_version,
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
   
    my $installed_version = $self->utils_otrs->is_installed( package => $params{package} || $self->package );
    if ( $installed_version ) {
        my $message = sprintf 'Addon %s is installed (%s)',
            $params{package} || $self->package, $installed_version;

        $self->logger->debug( message => $message );
        say $message;

        if ( $params{version} ) {
            my $check = $self->utils_otrs->_check_version(
                installed => $installed_version,
                requested => $params{version},
            );

            return 1 if $check;
        }
    }

    my $package_utils = OTRS::OPM::Installer::Utils::File->new(
        %file_opts,
        package      => $params{package} || $self->package,
        otrs_version => $self->otrs_version,
        verbose      => $self->verbose,
    );

    my $package_path = $package_utils->resolve_path;

    if ( !$package_path ) {
        my $message = sprintf "Could not find a .opm file for %s%s (OTRS version %s)",
            $params{package} || $self->package,
            ( $file_opts{version} ? " $file_opts{version}" : "" ),
            $self->otrs_version;

        $self->logger->error( fatal => $message );
        say $message;
        return;
    }

    my $parsed = OTRS::OPM::Parser->new(
        opm_file => $package_path,
    );

    $parsed->parse;

    if ( $parsed->error_string ) {
        my $message = sprintf "Cannot parse $package_path: %s", $parsed->error_string;
        $self->logger->error( fatal => $message );
        say $message;
        return;
    }

    if ( !$self->_check_matching_versions( $parsed, $self->otrs_version ) ) {
        my $message = sprintf 'framework versions of %s (%s) doesn\'t match otrs version %s',
            $parsed->name,
            join ( ', ', $parsed->framework ),
            $self->otrs_version;

        $self->logger->error( fatal => $message );
        say $message;
        return;
    }

    if ( $self->utils_otrs->is_installed( package => $parsed->name, version => $parsed->version ) ) {
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
    my @otrs_deps    = grep{ $_->{type} eq 'OTRS' }@dependencies;

    my $found_dependencies =  join ', ', map{ $_->{name} }@dependencies;
    say sprintf "Found dependencies: %s", $found_dependencies if $self->verbose;
    $self->logger->debug( message => sprintf "Found dependencies: %s", $found_dependencies );

    for my $cpan_dep ( @cpan_deps ) {
        my $module  = $cpan_dep->{name};
        my $version = $cpan_dep->{version};

        eval "use $module $version; 1;" and next;

        $self->_cpan_install( %{$cpan_dep} );
    }

    for my $otrs_dep ( @otrs_deps ) {
        my $module  = $otrs_dep->{name};
        my $version = $otrs_dep->{version};

        $self->utils_otrs->is_installed( %{$otrs_dep} ) and next;

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

    return $self->utils_otrs->manager;
}

sub _build_utils_otrs {
    OTRS::OPM::Installer::Utils::OTRS->new;
}

sub _build_otrs_version {
    shift->utils_otrs->otrs_version;
}

sub _check_matching_versions {
    my ($self, $parsed, $otrs_version) = @_;

    my ($major, $minor, $patch) = split /\./, $otrs_version;

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

OTRS::OPM::Installer - Install OTRS add ons

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  use OTRS::OPM::Installer;
  
  my $installer = OTRS::OPM::Installer->new;
  $installer->install( 'FAQ' );
  
  # or
  
  my $installer = OTRS::OPM::Installer->new();
  $installer->install( package => 'FAQ', version => '2.1.9' );

  # provide path to a config file
  my $installer = OTRS::OPM::Installer->new(
      conf => 'test.rc',
  );
  $installer->install( 'FAQ' );

=head1 DESCRIPTION

This is an alternate installer for OTRS addons. The standard OTRS package manager
currently does not install dependencies. OTRS::OPM::Installer takes care of those
dependencies and it can handle dependencies from different places:

=over 4

=item * OTRS.org

=over 4

=item * ITSM Packages

=item * Misc Packages

=back

=item * OPAR

=back

=head1 CONFIGURATION FILE

You can provide some basic configuration in a F<.opminstaller.rc> file:

  repository=http://ftp.otrs.org/pub/otrs/packages
  repository=http://ftp.otrs.org/pub/otrs/itsm/packages33
  repository=http://opar.perl-services.de
  repository=http://feature-addons.de/repo
  otrs_path=/srv/otrs

=head1 ACKNOWLEDGEMENT

The development of this packages was sponsored by http://feature-addons.de

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
