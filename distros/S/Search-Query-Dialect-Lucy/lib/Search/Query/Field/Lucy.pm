package Search::Query::Field::Lucy;
use Moo;
extends 'Search::Query::Field';
use Scalar::Util qw( blessed );

use namespace::autoclean;

has 'type'   => ( is => 'rw', default => sub {'char'} );
has 'is_int' => ( is => 'rw', default => sub {0} );
has 'analyzer' => ( is => 'rw' );    # TODO isa check
has 'range_query_class' =>
    ( is => 'rw', default => sub {'Lucy::Search::RangeQuery'} );
has 'term_query_class' =>
    ( is => 'rw', default => sub {'Lucy::Search::TermQuery'} );
has 'phrase_query_class' =>
    ( is => 'rw', default => sub {'Lucy::Search::PhraseQuery'} );
has 'proximity_query_class' =>
    ( is => 'rw', default => sub {'LucyX::Search::ProximityQuery'} );
has 'wildcard_query_class' =>
    ( is => 'rw', default => sub {'LucyX::Search::WildcardQuery'} );
has 'nullterm_query_class' =>
    ( is => 'rw', default => sub {'LucyX::Search::NullTermQuery'} );
has 'anyterm_query_class' =>
    ( is => 'rw', default => sub {'LucyX::Search::AnyTermQuery'} );

our $VERSION = '0.202';

=head1 NAME

Search::Query::Field::Lucy - query field representing a Lucy field

=head1 SYNOPSIS

 my $field = Search::Query::Field::Lucy->new( 
    name        => 'foo',
    alias_for   => [qw( bar bing )], 
 );

=head1 DESCRIPTION

Search::Query::Field::Lucy implements field
validation and aliasing in Lucy search queries.

=head1 METHODS

This class is a subclass of Search::Query::Field. Only new or overridden
methods are documented here.

=head2 BUILD

Available params are also standard attribute accessor methods.

=over

=item type

The column type. This may be a Lucy::FieldType object
or a simple string.

=item is_int

Set if C<type> matches m/int|num|date/.

=item analyzer

Set to a L<Lucy::Analysis::Analyzer>-based object (optional).

=item range_query_class

Defaults to L<Lucy::Search::RangeQuery>.

=item term_query_class

Defaults to L<Lucy::Search::TermQuery>.

=item phrase_query_class

Defaults to L<Lucy::Search::PhraseQuery>.

=item proximity_query_class

Defaults to L<LucyX::Search::ProximityQuery>.

=item wildcard_query_class

Defaults to L<LucyX::Search::WildcardQuery>.

=item nullterm_query_class

Defaults to L<LucyX::Search::NullTermQuery>.

=item anyterm_query_class

Defaults to L<LucyX::Search::AnyTermQuery>.

=back

=cut

sub BUILD {
    my $self = shift;

    # numeric types
    if (   exists $self->{type}
        && defined $self->{type}
        && !blessed( $self->{type} )
        && $self->{type} =~ m/int|date|num/ )
    {
        $self->{is_int} = 1;
    }

    # text types
    else {
        $self->{is_int} = 0;
    }

}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-query-dialect-Lucy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Query-Dialect-Lucy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Query::Dialect::Lucy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Query-Dialect-Lucy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Query-Dialect-Lucy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Query-Dialect-Lucy>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Query-Dialect-Lucy/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

