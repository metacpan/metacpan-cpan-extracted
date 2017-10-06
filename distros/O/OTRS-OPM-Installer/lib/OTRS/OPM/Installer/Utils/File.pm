package OTRS::OPM::Installer::Utils::File;
$OTRS::OPM::Installer::Utils::File::VERSION = '0.02';
# ABSTRACT: File related utility functions

use strict;
use warnings;

use File::HomeDir;
use File::Spec;
use File::Temp;
use HTTP::Tiny;
use IO::All;
use Moo;
use OTRS::OPM::Installer::Logger;
use OTRS::OPM::Installer::Utils::Config;
use OTRS::OPM::Installer::Types;
use OTRS::Repository;
use Regexp::Common qw(URI);
use Types::Standard qw(ArrayRef Str);

our $ALLOWED_SCHEME = 'HTTP';

has repositories => ( is => 'ro', isa => ArrayRef[Str], default => \&_repository_list );
has package      => ( is => 'ro', isa => Str, required => 1 );
has otrs_version => ( is => 'ro', isa => Str, required => 1 );
has version      => ( is => 'ro', isa => Str  );
has logger       => ( is => 'ro', default => sub{ OTRS::OPM::Installer::Logger->new } );
has rc_config    => ( is => 'ro', lazy => 1, default => \&_rc_config );
has conf         => ( is => 'ro' );

sub resolve_path {
    my ($self) = @_;

    my $path;

    my $package = $self->package;
    if ( $self->_is_url( $package ) ) {
        # download file
        $path = $self->_download( $package );
    }
    elsif ( -f $package ) {
        # do nothing, file already exists
        $path = $package;
    }
    else {
        my @repositories = @{ $self->repositories || [] };

        for my $repo ( @repositories ) {
            $repo .= '/otrs.xml' if '/otrs.xml' ne substr $repo, -9;
        }

        my $repo = OTRS::Repository->new(
            sources => \@repositories,
        );

        my ($otrs) = $self->otrs_version =~ m{\A(\d+\.\d+)};

        my ($url) = $repo->find(
            name    => $package,
            otrs    => $otrs,
            version => $self->version,
        );

        return if !$url;

        $path = $self->_download( $url );
    }

    return $path;
}

sub _repository_list {
    my ($self) = @_;

    my $config       = $self->rc_config;
    my $repositories = $config->{repository};

    return [] if !$repositories;
    return $repositories;        
}

sub _is_url {
    my ($self, $package) = @_;

    return $package =~ m{\A$RE{URI}{$ALLOWED_SCHEME}\z};
}

sub _download {
    my ($self, $url) = @_;

    my $file     = File::Temp->new->filename;
    my $response = HTTP::Tiny->new->mirror( $url, $file );

    $self->logger->notice( area => 'download', file => $file, success => $response->{success} );

    return $file;
}

sub _rc_config {
    my ($self) = @_;

    my $utils  = OTRS::OPM::Installer::Utils::Config->new( conf => $self->conf );
    my $config = $utils->rc_config;

    return $config;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Installer::Utils::File - File related utility functions

=head1 VERSION

version 0.02

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
