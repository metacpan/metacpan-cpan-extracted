package Search::Sitemap::URLStore::Memory;
use strict; use warnings;
our $VERSION = '2.13';
our $AUTHORITY = 'cpan:JASONK';
use Moose;
extends 'Search::Sitemap::URLStore';
use MooseX::Types::Moose qw( HashRef );
use Class::Trigger;
use namespace::clean -except => 'meta';

has 'storage'   => ( is => 'ro', isa => HashRef, default => sub { {} } );

sub get {
    my ( $self, $url ) = @_;
    return $self->storage->{ $url };
}

sub put {
    my $self = shift;

    $self->storage->{ $_->loc } = $_ for @_;

    return 1;
}

sub all { return values %{ shift->storage } }

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Search::Sitemap::URLStore::Memory - Search::Sitemap in-memory URL store

=head1 METHODS

=head2 put( @urls )

Add one or more L<Search::Sitemap::URL> objects to the URL store.

=head2 get( $url )

Retrieve a L<Search::Sitemap::URL> object from the URL store.

=head2 all

Return all the L<Search::Sitemap::URL> objects from the URL store.

=head1 SEE ALSO

L<Search::Sitemap>

L<Search::Sitemap::URLStore::Memory>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

