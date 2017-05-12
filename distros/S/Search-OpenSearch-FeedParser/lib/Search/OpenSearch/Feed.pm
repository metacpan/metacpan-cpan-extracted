package Search::OpenSearch::Feed;
use Moo;
use Types::Standard qw( HashRef ArrayRef Int Str Num Maybe );
use Carp;

our $VERSION = '0.101';

has 'entries'     => ( is => 'rw', isa => ArrayRef );
has 'total'       => ( is => 'rw', isa => Int );
has 'facets'      => ( is => 'rw', isa => Maybe[HashRef] );
has 'page_size'   => ( is => 'rw', isa => Int );
has 'offset'      => ( is => 'rw', isa => Int, default => sub {0} );
has 'query'       => ( is => 'rw', isa => Maybe[Str] );
has 'id'          => ( is => 'rw', isa => Str );
has 'title'       => ( is => 'rw', isa => Str );
has 'build_time'  => ( is => 'rw', isa => Maybe[Num] );
has 'search_time' => ( is => 'rw', isa => Maybe[Num] );
has 'suggestions' => ( is => 'rw', isa => Maybe[HashRef] );
has 'updated'     => ( is => 'rw', isa => Str );

=head1 NAME

Search::OpenSearch::Feed - client-side representation of a Search::OpenSearch::Response::XML

=head1 SYNOPSIS

 my $feed = Search::OpenSearch::FeedParser->new->parse( $sos_response_xml );
 printf("total: %s\n", $feed->total);
 for my $entry (@{ $feed->entries }) {
     printf(" uri: %s\n", $entry->{uri});
 }

=head1 DESCRIPTION

Search::OpenSearch::Feed represents the parsed response from Search::OpenSearch::Response::XML.
See L<Search::OpenSearch::FeedParser>.

=head1 METHODS

The following attributes are available:

=head2 entries

=head2 total

=head2 facets

=head2 page_size

=head2 offset

=head2 query

=head2 id

=head2 title

=head2 build_time

=head2 search_time

=head2 suggestions

=head2 updated

=cut

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch-feed at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch-Feed>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Feed


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch-Feed>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-OpenSearch-Feed>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-OpenSearch-Feed>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-OpenSearch-Feed/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to American Public Media Group for sponsoring this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 American Public Media Group.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
