package Search::OpenSearch::Federated;
use Moo;

our $VERSION = '0.007';

has 'debug' => ( is => 'rw' );
has 'fields' => (
    is      => 'rw',
    default => sub { [qw( title id author link summary tags modified )] }
);
has 'urls'             => ( is => 'rw' );
has 'total'            => ( is => 'rw' );
has 'facets'           => ( is => 'rw' );
has 'subtotals'        => ( is => 'rw' );
has 'timeout'          => ( is => 'rw' );
has 'normalize_scores' => ( is => 'rw' );
has 'version'          => ( is => 'rw', default => sub {$VERSION} );

use Carp;
use Data::Dump qw( dump );
use Parallel::Iterator qw( iterate_as_array );
use JSON;
use LWP::UserAgent;
use Scalar::Util qw( blessed );
use Search::Tools::XML;
use Data::Transformer;
use Normalize;

# we do not use WWW::OpenSearch because we need to pull out
# some non-standard data from the XML.
# we do use XML::Feed to parse XML responses.
use XML::Simple;
use XML::Feed;

my $OS_NS = 'http://a9.com/-/spec/opensearch/1.1/';

my $XMLer = Search::Tools::XML->new();

my $XML_ESCAPER = Data::Transformer->new(
    normal => sub { local ($_) = shift; $$_ = $XMLer->escape($$_); } );

sub search {
    my $self = shift;

    my $urls     = $self->{urls} or croak "no urls defined";
    my $num_urls = scalar @$urls;
    my @done     = iterate_as_array(
        sub {
            $self->_fetch( $_[1] );
        },
        $urls,
    );

    return $self->_aggregate( \@done );
}

sub _aggregate {
    my $self      = shift;
    my $responses = shift;
    my $results   = [];
    my $fields    = $self->fields;
    my $total     = 0;
    my %subtotals = ();
    my %facets    = ();

RESP: for my $resp (@$responses) {

        my $req_uri     = $resp->request->uri;
        my $resp_status = $resp->code;
        $self->debug
            and warn
            sprintf( "response for %s = %s\n", $req_uri, $resp_status );
        next RESP unless $resp_status =~ m/^2/;

        # temporary buffer to allow for normalizing scores
        my @resp_results  = ();
        my $highest_score = 0;

        if ( $resp->content_type eq 'application/json' ) {
            my $r = decode_json( $resp->content );
            if ( $r->{results} ) {
                @resp_results = @{ $r->{results} };
            }

            # must turn facets inside out in order
            # to aggregate counts correctly
            if ( $r->{facets} ) {
                for my $name ( keys %{ $r->{facets} } ) {
                    for my $facet ( @{ $r->{facets}->{$name} } ) {
                        $facets{$name}->{ $facet->{term} } += $facet->{count};
                    }
                }
            }
            $total += $r->{total} || 0;
            $subtotals{$req_uri} = $r->{total};
        }
        elsif ( $resp->content_type eq 'application/xml' ) {
            my $xml = $resp->content;

            #warn $xml;
            my $feed = XML::Feed->parse( \$xml );

            if ( !$feed ) {
                warn XML::Feed->errstr;
                next RESP;
            }

            #dump $feed;

            #
            # we must re-escape the XML content since the feed parser
            # and XML::Simple will escape values automatically
            #
            my @entries;
            for my $item ( $feed->entries ) {
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
                my $fields = XMLin( $content->body, NoAttr => 1 );

                #dump $fields;

                for my $f ( keys %$fields ) {
                    $e->{$f} = $fields->{$f};
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
            my $xml_feed = XMLin( $feed->as_xml, NoAttr => 1 );

            #dump($xml_feed);

            # must turn facets inside out in order
            # to aggregate counts correctly
            if ( $xml_feed->{category}->{sos}->{facets} ) {
                my $facet_feed = $xml_feed->{category}->{sos}->{facets};
                for my $name ( keys %$facet_feed ) {
                    if ( ref $facet_feed->{$name}->{$name} eq 'ARRAY' ) {
                        for my $facet ( @{ $facet_feed->{$name}->{$name} } ) {
                            $facets{$name}->{ $facet->{term} }
                                += $facet->{count};
                        }
                    }
                    elsif ( ref $facet_feed->{$name}->{$name} eq 'HASH' ) {
                        my $facet = $facet_feed->{$name}->{$name};
                        $facets{$name}->{ $facet->{term} } = $facet->{count};
                    }

                }
            }

            my $atom = $feed->{atom};
            my $this_total = $atom->get( $OS_NS, 'totalResults' );
            $total += $this_total;
            $subtotals{$req_uri} = $this_total;
            push @resp_results, @entries;
        }
        else {
            croak sprintf( "Unsupported response type '%s' for %s\n",
                scalar $resp->content_type, $req_uri );
        }

        # normalize scores
        if ( $self->normalize_scores ) {
            my $normalizer = Normalize->new( 'round_to' => 0.001 );
            my %normalized = ();
            my $i          = 0;

            # compute
            for my $r (@resp_results) {
                $normalized{ $i++ } = $r->{score};
            }
            $normalizer->normalize_to_max( \%normalized );

            # apply
            for my $idx ( keys %normalized ) {
                $resp_results[$idx]->{score} = ( $normalized{$idx} * 1000 );
            }
        }

        # aggregate
        push @$results, @resp_results;

    }

    # transform facets back into arrays of count/term pairs
    my %facets_norm;
    for my $name ( keys %facets ) {
        my @diads = ();
        for my $term ( keys %{ $facets{$name} } ) {
            push @diads, { term => $term, count => $facets{$name}->{$term} };
        }
        $facets_norm{$name} = [@diads];
    }
    $self->{facets}    = \%facets_norm;
    $self->{total}     = $total;
    $self->{subtotals} = \%subtotals;
    return [ sort { $b->{score} <=> $a->{score} } @$results ];
}

sub _fetch {
    my $self = shift;
    my $url  = shift or croak "url required";
    my $ua   = LWP::UserAgent->new();
    $ua->agent( 'sos-fedsearch ' . $VERSION );
    $ua->timeout( $self->{timeout} ) if $self->{timeout};

    my $response = $ua->get($url);

    $self->debug and warn "got response for $url: " . $response->status_line;
    return $response;
}

1;

__END__

=head1 NAME

Search::OpenSearch::Federated - aggregate OpenSearch results

=head1 SYNOPSIS

 my $ms = Search::OpenSearch::Federated->new(
    urls    => [
        'http://some-site.org/search?q=foo',
        'http://some-other-site.org/search?q=foo',
    ],
    timeout => 10,  # very generous
 );

 my $results = $ms->search();
 for my $r (@$results) {
     printf("title=%s", $r->title);
     printf("uri=%s",   $r->uri);
     print "\n";
 }

=head1 DESCRIPTION

Search::OpenSearch::Federated is for aggregating multiple OpenSearch responses
into a single result set. Use it as a client for Search::OpenSearch::Engine-powered
servers or for any server that provides OpenSearch-style results.

=head1 METHODS

Search::OpenSearch::Federated isa Search::Tools::Object.

=head2 new( I<args> )

Constructor. I<args> should include key C<urls> with value of
an array reference. Supported I<args> keys are:

=over

=item urls I<arrayref>

=item timeout I<n>

=item fields I<arrayref>

=item debug 0|1

=item normalize_scores 0|1

If true, all result scores are run through the L<Normalize> module to (hopefully)
help create parity amongst the result sets.

=item version

Defaults to $VERSION package var.

=back

=head2 search

Execute the search. Returns array ref of results sorted by score.

=head2 fields

Returns fields set in new().

=head2 total

Return total hits.

=head2 subtotals

Returns hash ref of subtotal for each URL, keys being
the values of urls().

=head2 facets

Returns hash ref of aggregated facets for all URLs.

=head1 COPYRIGHT

Copyright 2013 - American Public Media Group

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch-federated at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch-Federated>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Federated

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch-Federated>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-OpenSearch-Federated>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-OpenSearch-Federated>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-OpenSearch-Federated/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to American Public Media and the state of Minnesota for sponsoring the 
development of this module.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

