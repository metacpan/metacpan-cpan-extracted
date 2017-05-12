package OTRS::Repository::Source;

# ABSTRACT: Parser for a single otrs.xml file

use strict;
use warnings;

use Moo;
use HTTP::Tiny;
use XML::LibXML;
use Regexp::Common qw(URI);

our $VERSION = 0.05;

our $ALLOWED_SCHEME = 'HTTP';

has url      => ( is => 'ro', required => 1, isa     => sub { die "No valid URI" unless $_[0] =~ m{\A$RE{URI}{$ALLOWED_SCHEME}\z} } );
has content  => ( is => 'ro', lazy     => 1, builder => \&_get_content );
has tree     => ( is => 'ro', lazy     => 1, builder => \&_build_tree );
has error    => ( is => 'rwp' );
has packages => ( is => 'rwp', default => sub { {} }, isa => sub { die "No hashref" unless ref $_[0] eq 'HASH' } );
has parsed   => ( is => 'rwp', predicate => 1 );

sub find {
    my ($self, %params) = @_;

    return if !exists $params{name};
    return if !exists $params{otrs};

    my $package  = $params{name};
    my $otrs     = $params{otrs};

    if ( !defined $package || !defined $otrs ) {
        return;
    }

    if ( !$self->has_parsed ) {
        $self->_parse( %params );
    }

    my %packages = %{ $self->packages };

    return if !$packages{$package};
    return if !$packages{$package}->{$otrs};

    my $wanted = $params{version} || $packages{$package}->{$otrs}->{latest};
    return $packages{$package}->{$otrs}->{versions}->{$wanted};
}

sub list {
    my ($self, %params) = @_;

    if ( !$self->has_parsed ) {
        $self->_parse( %params );
    }

    my %packages = %{ $self->packages };
    my $otrs     = $params{otrs};

    my @packages = sort keys %packages;

    if ( $otrs ) {
        @packages = grep{ $packages{$_}->{$otrs} }@packages;
    }

    return @packages;
}

sub _parse {
    my ($self, %params) = @_;

    return if !$self->tree;

    my %packages = %{ $self->packages };

    my @repo_packages = $self->tree->findnodes( 'Package' );
    my $base_url      = $self->url;
    $base_url         =~ s{\w+\.xml\z}{};

    REPO_PACKAGE:
    for my $repo_package ( @repo_packages ) {
        my $name       = $repo_package->findvalue( 'Name' );
        my @frameworks = $repo_package->findnodes( 'Framework' );
        my $file       = $repo_package->findvalue( 'File' );

        my $version    = $repo_package->findvalue( 'Version' );

        FRAMEWORK:
        for my $framework ( @frameworks ) {
            my $otrs_version  = $framework->textContent;
            my $short_version = join '.', (split /\./, $otrs_version, 3)[0..1];
            my $saved_version = $packages{$name}->{$short_version}->{latest};

            if ( !$saved_version ) {
                $packages{$name}->{$short_version} = {
                    latest   => $version,
                    versions => {
                      $version => sprintf "%s%s", $base_url, $file,
                    },
                };
            }
            elsif ( $self->_version_is_newer( $version, $saved_version ) ) {
                $packages{$name}->{$short_version}->{latest} = $version;
                $packages{$name}->{$short_version}->{versions}->{$version} =
                    sprintf "%s%s", $base_url, $file;
            }
            else {
                $packages{$name}->{$short_version}->{versions}->{$version} =
                    sprintf "%s%s", $base_url, $file;
            }
        }
    }

    $self->_set_parsed( 1 );
    $self->_set_packages( \%packages );

    return 1;
}

sub _version_is_newer {
    my ($self, $new, $old) = @_;

    my @new_levels = split /\./, $new;
    my @old_levels = split /\./, $old;

    for my $i ( 0 .. ( $#new_levels > $#old_levels ? @new_levels : @old_levels ) ) {
        if ( !$old_levels[$i] || $new_levels[$i] > $old_levels[$i] ) {
            return 1;
        }
        elsif ( $new_levels[$i] < $old_levels[$i] ) {
            return 0;
        }
    }

    return 1;
}

sub _get_content {
    my $self = shift;
    my $res  = HTTP::Tiny->new->get( $self->url );

    $self->_set_error( undef );
    
    if ( $res->{success} ) {
        return $res->{content};
    }

    $self->_set_error( $res->{reason} );

    return '<otrs_packages></otrs_packages>';
}

sub _build_tree {
    my $self = shift;

    $self->_set_error( undef );

    my $tree;
    eval {
        my $parser = XML::LibXML->new->parse_string( $self->content );
        $tree      = $parser->getDocumentElement;
    } or $self->_set_error( $@ );

    return $tree;
}

1;

__END__

=pod

=head1 NAME

OTRS::Repository::Source - Parser for a single otrs.xml file

=head1 VERSION

version 0.05

=head1 AUTHOR

Renee Baecker <github@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
