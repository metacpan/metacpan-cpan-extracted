package OPM::Repository::Source;

use v5.10;

# ABSTRACT: Parser for a single {otrs|otobo}.xml file

use strict;
use warnings;

our $VERSION = '1.0.0'; # VERSION

use Moo;
use HTTP::Tiny;
use HTTP::Tiny::FileProtocol;
use XML::LibXML;
use Regexp::Common qw(URI);

our $ALLOWED_SCHEME = [ 'HTTP', 'file' ];

has url      => ( is => 'ro', required => 1, isa     => \&_check_uri );
has content  => ( is => 'ro', lazy     => 1, builder => \&_get_content );
has tree     => ( is => 'ro', lazy     => 1, builder => \&_build_tree );
has error    => ( is => 'rwp' );
has packages => ( is => 'rwp', default => sub { {} }, isa => sub { die "No hashref" unless ref $_[0] eq 'HASH' } );
has parsed   => ( is => 'rwp', predicate => 1 );
has product  => ( is => 'ro', default => sub { 'otrs' } );

sub find {
    my ($self, %params) = @_;

    return if !exists $params{name};
    return if !exists $params{framework};

    my $package   = $params{name};
    my $framework = $params{framework};

    if ( !defined $package || !defined $framework ) {
        return;
    }

    if ( !$self->has_parsed ) {
        $self->_parse( %params );
    }

    my %packages = %{ $self->packages };

    return if !$packages{$package};
    return if !$packages{$package}->{$framework};

    my $wanted = $params{version} || $packages{$package}->{$framework}->{latest};
    return $packages{$package}->{$framework}->{versions}->{$wanted};
}

sub list {
    my ($self, %params) = @_;

    if ( !$self->has_parsed ) {
        $self->_parse( %params );
    }

    my %packages  = %{ $self->packages };
    my $framework = $params{framework};

    my @package_names = sort keys %packages;

    if ( $framework ) {
        @package_names = grep{ $packages{$_}->{$framework} }@package_names;
    }

    if ( $params{details} ) {
        my @package_list;

        NAME:
        for my $name ( @package_names ) {
            my @all_framework_versions = $framework ? $framework : keys %{ $packages{$name} || {} };

            OPM_VERSION:
            for my $framework_version ( @all_framework_versions ) {

                VERSION:
                for my $version ( keys %{ $packages{$name}->{$framework_version}->{versions} || {} } ) {
                    push @package_list, {
                        name    => $name,
                        version => $version,
                        url     => $packages{$name}->{$framework_version}->{versions}->{$version},
                    }
                }
            }
        }

        @package_names = sort { $a->{name} cmp $b->{name} || $a->{version} cmp $b->{version} } @package_list;
    }

    return @package_names;
}

sub _check_uri {
    my @allowed_schemes = ref $ALLOWED_SCHEME ? @{ $ALLOWED_SCHEME } : $ALLOWED_SCHEME;

    my $matches;

    SCHEME:
    for my $scheme ( @allowed_schemes ) {
        my $regex = ( lc $scheme eq 'http' ) ?
            $RE{URI}{HTTP}{-scheme => qr/https?/} :
            $RE{URI}{$scheme};

        if ( $_[0] =~ m{\A$regex\z} ) {
            $matches++;
            last SCHEME;
        }
    }

    die "No valid URI" unless $matches;
    return 1;
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
            my $framework_version  = $framework->textContent;
            my $short_version = join '.', (split /\./, $framework_version, 3)[0..1];
            my $saved_version = $packages{$name}->{$short_version}->{latest};

            my $minimum = $framework->findvalue('@Minimum');
            my $maximum = $framework->findvalue('@Maximum');

            if ( !$saved_version ) {
                $packages{$name}->{$short_version} = {
                    latest       => $version,
                    min_versions => {
                    },
                    max_versions => {
                    },
                    versions     => {
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

    return sprintf '<%s_packages></%s_packages>', ( $self->product ) x 2;
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

=encoding UTF-8

=head1 NAME

OPM::Repository::Source - Parser for a single {otrs|otobo}.xml file

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

    use OPM::Repository::Source;

    my $source = OPM::Repository::Source->new(
        url => 'http://opar.perl-services.de/otrs.xml',
    );

    my @packages_in_source = $source->list;

    # check if TicketTemplates is avaialable at the
    # given repository/source
    my $found = $source->find(
        name      => 'TicketTemplates',
        framework => '3.0',
    );

=head1 ATTRIBUTES

=over 4

=item * content

The content of the sources' I<{otrs,otobo}.xml> file.

=item * error

If an error occurs, the message is in C<error>.

=item * has_parsed

=item * packages

A hash reference that contains information about all packages
that are available in the repository/source.

=item * parsed

=item * product

I<otrs|otobo>

=item * tree

=item * url

URL of the I<{otrs,otobo}.xml> file that represents the repository.

=back

=head1 METHODS

=head2 find

=head2 list

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
