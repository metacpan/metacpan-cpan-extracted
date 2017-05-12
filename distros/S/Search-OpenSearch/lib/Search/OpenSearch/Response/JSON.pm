package Search::OpenSearch::Response::JSON;
use Moose;
use Carp;
extends 'Search::OpenSearch::Response';
use JSON;

our $VERSION = '0.409';

sub stringify {
    my $self = shift;

    my $resp = $self->as_hash;
    
    # in devel mode use pretty()
    return $self->debug
        ? JSON->new->utf8->pretty(1)->encode($resp)
        : encode_json($resp);
}

sub content_type { return 'application/json; charset=utf-8' }

1;

__END__

=head1 NAME

Search::OpenSearch::Response::JSON - provide search results in JSON format

=head1 SYNOPSIS

 use Search::OpenSearch;
 my $engine = Search::OpenSearch->engine(
    type    => 'KSx',
    index   => [qw( path/to/index1 path/to/index2 )],
    facets  => {
        names       => [qw( color size flavor )],
        sample_size => 10_000,
    },
    fields  => [qw( color size flavor )],
 );
 my $response = $engine->search(
    q           => 'quick brown fox',   # query
    s           => 'score desc',        # sort order
    o           => 0,                   # offset
    p           => 25,                  # page size
    h           => 1,                   # highlight query terms in results
    c           => 0,                   # return count stats only (no results)
    L           => 'field|low|high',    # limit results to inclusive range
    f           => 1,                   # include facets
    r           => 1,                   # include results
    format      => 'JSON',              # or XML
 );
 print $response;

=head1 DESCRIPTION

Search::OpenSearch::Response::JSON serializes to JSON.

The OpenSearch specification is for XML, but some alternative JSON
formats are defined at http://www.opensearch.org/Community/JSON_Formats.

This class follows none of the examples exactly, but is fairly close
to the NYTimes format.

=head1 METHODS

This class is a subclass of Search::OpenSearch::Response. 
Only new or overridden methods are documented here.

=head2 stringify

Returns the Response in JSON format.

Response objects are overloaded to call stringify().

=head2 content_type

Returns appropriate MIME type for the format returned by stringify().

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Response


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-OpenSearch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-OpenSearch>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-OpenSearch/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
