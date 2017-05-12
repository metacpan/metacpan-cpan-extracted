package Search::Sitemap::URLStore;
use strict; use warnings;
our $VERSION = '2.13';
our $AUTHORITY = 'cpan:JASONK';
use Moose;
use Class::Trigger;
use Carp qw( croak );
use namespace::clean -except => [qw( meta add_trigger call_trigger )];

after 'put' => sub {
    my $self = shift;
    $self->call_trigger( put => @_ );
};

sub put { croak "Abstract method 'put' called" }
sub get { croak "Abstract method 'get' called" }
sub all { croak "Abstract method 'all' called" }

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Search::Sitemap::URLStore - Abstract base class for Search::Sitemap URL stores

=head1 DESCRIPTION

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

