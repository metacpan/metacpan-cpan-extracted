package SWISH::Prog::Xapian::Results;
use strict;
use warnings;
use base qw( SWISH::Prog::Results );
use SWISH::Prog::Xapian::Result;

__PACKAGE__->mk_ro_accessors(qw( mset prop_id_map query facets ));

our $VERSION = '0.09';

=head1 NAME

SWISH::Prog::Xapian::Results - search results for Swish3 Xapian backend

=head1 SYNOPSIS

 # see SWISH::Prog::Results
 
=cut

=head1 METHODS

Only new and overridden methods are documented here. See
the L<SWISH::Prog::Results> documentation.

=cut

=head2 mset

Get the internal Search::Xapian::MSet object. This is a read-only
accessor method.

=head2 prop_id_map 

Get the read-only internal map for PropertyNames to id values.

=head2 query

Get the Search::Query object representing the original query string.

=head2 facets

If C<get_facets> was defined in Searcher->search, returns hash ref
of facet values and counts.

=head2 next

Returns the next SWISH::Prog::Xapian::Result from the Results iterator.

=cut

sub next {
    my $self = shift;
    my $i    = $self->{_i}++;
    return if $i >= $self->hits;
    my $mit = $self->{mset}->get_msetiterator($i);
    return SWISH::Prog::Xapian::Result->new(
        prop_id_map => $self->{prop_id_map},
        doc         => $mit->get_document(),
        score       => $mit->get_percent() * 10,    # scale to 1000
    );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan dot org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-swish-prog-xapian at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog-Xapian>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog::Xapian

You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog-Xapian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog-Xapian>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-Xapian>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog-Xapian>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
