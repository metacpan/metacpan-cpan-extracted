package SWISH::Prog::Lucy::Results;
use strict;
use warnings;

our $VERSION = '0.25';

use base qw( SWISH::Prog::Results );
use SWISH::Prog::Lucy::Result;

__PACKAGE__->mk_accessors(qw( find_relevant_fields ));
__PACKAGE__->mk_ro_accessors(qw( id lucy_hits property_map ));

=head1 NAME

SWISH::Prog::Lucy::Results - search results for Swish3 Lucy backend

=head1 SYNOPSIS

  my $results = $searcher->search($query);
  $results->find_relevant_fields(1);
  while ( my $result = $results->next ) {
      my $fields = $result->relevant_fields;
      for my $f (@$fields) {
          printf("%s matched %s\n", $result->uri, $f);
      }
  }

=head1 DESCRIPTION

SWISH::Prog::Lucy::Results is an Apache Lucy based Results
class for Swish3.

=head1 METHODS

Only new and overridden methods are documented here. See
the L<SWISH::Prog::Results> documentation.

=head2 find_relevant_fields I<1|0>

Set to true (1) to locate the fields the query matched
for each result. Default is false (0).

NOTE that the Indexer must have had highlightable_fields set
to true (1) in order for find_relevant_fields to work.

=head2 next

Returns the next SWISH::Prog::Lucy::Result object from the result set.

=cut

sub next {
    my $hit = $_[0]->lucy_hits->next or return;

    # see http://markmail.org/message/xoqwxofwphlowqxf
    my @relevant_fields;
    if ( $_[0]->find_relevant_fields ) {
        my $searcher = $_[0]->{_searcher};
        my $compiler = $_[0]->{_compiler};
        my $doc_vec  = $searcher->fetch_doc_vec( $hit->get_doc_id );
        my $schema   = $searcher->get_schema();
        for my $field ( @{ $schema->all_fields } ) {
            my $spans = $compiler->highlight_spans(
                searcher => $searcher,
                doc_vec  => $doc_vec,
                field    => $field,
            );
            if (@$spans) {
                push @relevant_fields, $field;
            }
        }
    }
    return SWISH::Prog::Lucy::Result->new(
        relevant_fields => \@relevant_fields,
        doc             => $hit,
        property_map    => $_[0]->{property_map},

        # scale like xapian, swish-e
        score => ( int( $hit->get_score * 1000 ) || 1 ),
        id => $_[0]->id,
    );
}

=head2 lucy_hits

Get the internal Lucy::Search::Hits object.

=head2 property_map

Get the read-only hashref of PropertyNameAlias to PropertyName
values.

=head2 id

Get the read-only unique id from the parent Searcher.

=cut

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog-lucy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog-Lucy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog::Lucy


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-Lucy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog-Lucy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog-Lucy>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog-Lucy/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

