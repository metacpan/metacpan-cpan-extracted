package Search::OpenSearch::FeedParser;
use Moo;
use Types::Standard qw( ArrayRef Bool );
use Search::OpenSearch::Feed;
use Carp;
use Data::Dump qw( dump );
use XML::Feed;
use XML::Simple;
use Data::Transformer;
use Search::Tools::XML;
use Scalar::Util qw( blessed );

has 'debug' =>
    ( is => 'rw', isa => Bool, default => sub { $ENV{SOS_DEBUG} || 0 } );
has 'fields' => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub {
        [qw( title id link summary modified tags category author issued )];
    },
);

=head1 NAME

Search::OpenSearch::FeedParser - parse Search::OpenSearch::Response::XML 

=cut

our $VERSION = '0.101';

my $XMLer       = Search::Tools::XML->new();
my $XML_ESCAPER = Data::Transformer->new(
    normal => sub { local ($_) = shift; $$_ = $XMLer->escape($$_); } );

=head1 SYNOPSIS

 use Search::OpenSearch::FeedParser;
 my $parser = Search::OpenSearch::FeedParser->new();
 my $feed = $parser->parse( $sos_response );

=head1 DESCRIPTION

Search::OpenSearch::FeedParser is the client parser for Search::OpenSearch::Response::XML.
It is similar in concept to WWW::OpenSearch but because the SOS::Response::XML format
is a superset of the OpenSearch standard, this module implements a different API.

=head1 METHODS

=head2 new( I<args> )

Instantiate a new FeedParser object. You can re-use a single FeedParser object to parse
multiple responses.

I<args> should be a hash of key/value pairs, including:

=over

=item debug I<bool>

=item fields I<arrayref>

=back

=cut

=head2 debug([I<bool>])

Get/set the debug flag for the parser.

=head2 fields

Get/set the arrayref of field names the parser should expect in each response.

=head2 parse( I<sos_response> )

Parse the contents of I<sos_response> and return a Search::OpenSearch::Feed object.
I<sos_response> may be a string of XML or a Search::OpenSearch::Response::XML object.

=cut 

sub parse {
    my $self = shift;
    my $resp = shift or croak "sos_response required";

    # if it is an object, stringify it
    my $xml = "$resp";

    my $fields = $self->fields;
    my %feed;
    my $xfeed = XML::Feed->parse( \$xml );
    if ( !$xfeed ) {
        croak "invalid XML response: " . XML::Feed->errstr;
    }

    #dump $xfeed;

    #
    # we must re-escape the XML content since the feed parser
    # and XML::Simple will escape values automatically
    #
    my @entries;
    for my $item ( $xfeed->entries ) {
        my $e = {};
        for my $f (@$fields) {
            $e->{$f} = $item->$f;
            if ( blessed( $e->{$f} ) ) {

                #dump( $e->{$f} );
                if ( $e->{$f}->isa('XML::Feed::Content') ) {
                    $e->{$f} = $XMLer->escape( $e->{$f}->body );
                }
                elsif ( $e->{$f}->isa('DateTime') ) {
                    $e->{$f} = $e->{$f}->epoch;
                }
            }
            else {
                $e->{$f} = $XMLer->escape( $e->{$f} );
            }
        }

        #dump $e;
        my $content = $item->content;
        my $xfields = XMLin( $content->body, NoAttr => 0 );

        #dump $fields;

        for my $f ( keys %$xfields ) {
            $e->{$f} = $xfields->{$f};
            if ( ref $e->{$f} ) {
                $XML_ESCAPER->traverse( $e->{$f} );
            }
            else {
                $e->{$f} = $XMLer->escape( $e->{$f} );
            }
        }

        # massage some field names
        $e->{mtime} = delete $e->{modified};
        $e->{uri}   = delete $e->{id};

        #dump $content;
        #dump $e;
        push @entries, $e;

    }

    # facets require digging into the raw xml
    my $xml_feed = XMLin( $xfeed->as_xml, NoAttr => 0 );

    #dump($xml_feed);

    # must turn facets inside out in order
    # to aggregate counts correctly
    my %facets;
    if ( $xml_feed->{category}->{sos}->{facets} ) {
        my $facet_feed = $xml_feed->{category}->{sos}->{facets};
        for my $name ( keys %$facet_feed ) {
            for my $facet ( @{ $facet_feed->{$name}->{$name} } ) {
                $facets{$name}->{ $facet->{term} } += $facet->{count};
            }
        }
    }

    $feed{total}       = $xml_feed->{'opensearch:totalResults'};
    $feed{query}       = $xml_feed->{'opensearch:Query'}->{searchTerms};
    $feed{page_size}   = $xml_feed->{'opensearch:itemsPerPage'};
    $feed{offset}      = $xml_feed->{'opensearch:startIndex'};
    $feed{updated}     = $xml_feed->{updated};
    $feed{title}       = $xml_feed->{title};
    $feed{id}          = $xml_feed->{id};
    $feed{build_time}  = $xml_feed->{category}->{sos}->{build_time};
    $feed{search_time} = $xml_feed->{category}->{sos}->{search_time};
    $feed{suggestions} = $xml_feed->{category}->{sos}->{suggestions};
    $feed{facets}      = \%facets;
    $feed{entries}     = \@entries;
    return Search::OpenSearch::Feed->new(%feed);
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch-feed at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch-FeedParser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Feed


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch-FeedParser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-OpenSearch-FeedParser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-OpenSearch-FeedParser>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-OpenSearch-FeedParser/>

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

