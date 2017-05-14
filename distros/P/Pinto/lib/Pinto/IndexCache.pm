# ABSTRACT: Manages indexes files from upstream repositories

package Pinto::IndexCache;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use Package::Locator;

#-------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#-------------------------------------------------------------------------------

has repo => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    weak_ref => 1,
    required => 1,
);

has locator => (
    is      => 'ro',
    isa     => 'Package::Locator',
    handles => [qw(clear_cache)],
    builder => '_build_locator',
    lazy    => 1,
);

#-------------------------------------------------------------------------------

sub _build_locator {
    my ($self) = @_;

    my @urls      = $self->repo->config->sources_list;
    my $cache_dir = $self->repo->config->cache_dir;
    my $locator   = Package::Locator->new(
        repository_urls => \@urls,
        cache_dir       => $cache_dir
    );

    return $locator;
}

#-------------------------------------------------------------------------------

sub locate {
    my ( $self, @args ) = @_;

    return $self->locator->locate(@args);
}

#-------------------------------------------------------------------------------

sub contents {
    my ($self) = @_;

    my %seen;
    for my $index ( $self->locator->indexes() ) {
        for my $dist ( values %{ $index->distributions() } ) {
            next if exists $seen{ $dist->{path} };
            $dist->{packages} ||= [];    # Prevent possible undef
            delete $_->{distribution} for @{ $dist->{packages} };
            $seen{ $dist->{path} } = $dist;
        }
    }

    return @seen{ sort keys %seen };

}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-------------------------------------------------------------------------------

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer BenRifkah Fowler Jakob Voss Karen Etheridge Michael
G. Bergsten-Buret Schwern Oleg Gashev Steffen Schwigon Tommy Stanton
Wolfgang Kinkeldei Yanick Boris Champoux hesco popl Däppen Cory G Watson
David Steinbrunner Glenn

=head1 NAME

Pinto::IndexCache - Manages indexes files from upstream repositories

=head1 VERSION

version 0.097

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
