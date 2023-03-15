package Museum::TePapa;

use 5.34.0;
use strictures 2;

use JSON::MaybeXS;
use LWP::UserAgent;
use Moo;
use URI::QueryParam;

use namespace::clean;

=head1 NAME

Museum::TePapa - an interface to the Te Papa museum API

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This provides handy methods for access the various endpoints of the Te Papa
museum API. See L<https://data.tepapa.govt.nz/docs/index.html> for information
on them. You will need an API key, this doesn't handle the guest key mechanism.

    use Museum::TePapa;

    my $tepapa = Museum::TePapa->new( key => 'yoursecretkey' );
    my $result = $tepapa->object_search( $query, { limit => 3 } );
    my $result = $tepapa->place( $id, { ... parameters ... } );
    my $result = $tepapa->taxon_related( $id, { ... parameters ... } );

    # This provides results in batches through the callback
    $tepapa->media_scroll( $callback, { ... parameters ... } );

=head1 METHODS

=head2 new

    my $tepapa = Museum::TePapa->new( key => 'yoursecretkey' );

Create a new instance of the API interface. 

=head2 agent_search( $query, { ... parameters ... } )

=head2 agent( $id, { ... parameters ... } )

=head2 agent_related( $id, { ... parameters ... } )

=head2 agent_scroll( $id, { ... parameters ... } )

=head2 category_search( $query, { ... parameters ... } )

=head2 category( $id, { ... parameters ... } )

=head2 category_related( $id, { ... parameters ... } )

=head2 category_scroll( $id, { ... parameters ... } )

=head2 document_search( $query, { ... parameters ... } )

=head2 document( $id, { ... parameters ... } )

=head2 document_related( $id, { ... parameters ... } )

=head2 document_scroll( $id, { ... parameters ... } )

=head2 fieldcollection_search( $query, { ... parameters ... } )

=head2 fieldcollection( $id, { ... parameters ... } )

=head2 fieldcollection_related( $id, { ... parameters ... } )

=head2 fieldcollection_scroll( $id, { ... parameters ... } )

=head2 group_search( $query, { ... parameters ... } )

=head2 group( $id, { ... parameters ... } )

=head2 group_related( $id, { ... parameters ... } )

=head2 group_scroll( $id, { ... parameters ... } )

=head2 media_search( $query, { ... parameters ... } )

=head2 media( $id, { ... parameters ... } )

=head2 media_related( $id, { ... parameters ... } )

=head2 media_scroll( $id, { ... parameters ... } )

=head2 object_search( $query, { ... parameters ... } )

=head2 object( $id, { ... parameters ... } )

=head2 object_related( $id, { ... parameters ... } )

=head2 object_scroll( $id, { ... parameters ... } )

=head2 place_search( $query, { ... parameters ... } )

=head2 place( $id, { ... parameters ... } )

=head2 place_related( $id, { ... parameters ... } )

=head2 place_scroll( $id, { ... parameters ... } )

=head2 taxon_search( $query, { ... parameters ... } )

=head2 taxon( $id, { ... parameters ... } )

=head2 taxon_related( $id, { ... parameters ... } )

=head2 taxon_scroll( $id, { ... parameters ... } )

=head2 topic_search( $query, { ... parameters ... } )

=head2 topic( $id, { ... parameters ... } )

=head2 topic_related( $id, { ... parameters ... } )

=head2 topic_scroll( $id, { ... parameters ... } )

=head2 search( $query, { ... parameters ... } )

=head2 search_scroll( $id, { ... parameters ... } )

All these methods map directly on to the API endpoints referenced in the API
documentation, with some small naming differences. C<_search> puts the query
into the C<q> parameter.

C<_scroll> has a different behaviour to the others: it requires a callback
function. This callback will be called with every batch of data fetched. If it
returns a true value, then the collection process will stop.

=cut

my @endpoints = qw( agent category document fieldcollection group media object place taxon topic );
{
    no strict 'refs';
    foreach my $ep (@endpoints) {
        *{"Museum::TePapa::${ep}_search"}  = sub { shift->_resource_search( $ep, @_ ); };
        *{"Museum::TePapa::${ep}"}         = sub { shift->_resource( $ep, @_ ); };
        *{"Museum::TePapa::${ep}_related"} = sub { shift->_resource_related( $ep, @_ ); };
        *{"Museum::TePapa::${ep}_scroll"}  = sub { shift->_resource_scroll( $ep, @_ ); };
    }
    *{"Museum::TePapa::search"}        = sub { shift->_resource_search( 'search', @_ ); };
    *{"Museum::TePapa::search_scroll"} = sub { shift->_resource_scroll( 'search', @_ ); };
}

sub _resource_search {
    my ($self, $resource, $query, $params) = @_;

    $params = {} unless $params;
    return $self->_query('GET', "/$resource", { q => $query, %$params });
}

sub _resource {
    my ($self, $resource, $id, $params) = @_;

    $params = {} unless $params;
    return $self->_query('GET', "/$resource/$id", $params );
}

sub _resource_related {
    my ($self, $resource, $id, $params) = @_;

    $params = {} unless $params;
    return $self->_query('GET', "/$resource/${id}_related", $params );
}

sub _resource_scroll {
    my ($self, $resource, $callback, $params) = @_;

    $params = {} unless $params;
    $params->{duration} = 5 unless $params->{duration}; # default of 5 minutes

    my $path = "/$resource/_scroll";
    my $url = URI->new($self->url_base . $path);
    if ($params) {
        for my $p (keys %$params) {
            $url->query_param($p => $params->{$p});
        }
    }

    my $ua = LWP::UserAgent->new;
    $ua->agent("Museum::TePapa/$VERSION");

    my $res;
    my $json = JSON::MaybeXS->new();
    my $stopnow = 0;
    my $method = 'POST';
    do {
        my $req = HTTP::Request->new(
            $method => $url,
            [
                'Accept' => 'application/json; charset=UTF-8',
                'x-api-key'    => $self->key,
            ]
        );
        $res = $ua->simple_request($req);
        if ($res->code eq '303') {
            my $content = $json->decode($res->decoded_content);
            $stopnow = $callback->($content);
            $url = $self->url_base . $res->header('Location');
        } elsif ($res->code ne '204') {
            die "Unexpected result from scroll: ".$res->status_line."\n";
        }
        # Replace the URL with the new location
        $method = 'GET'; # first is a post, the rest are gets
    } while (!$stopnow && $res->code eq '303');
}

sub _query {
    my ($self, $method, $path, $params) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent("Museum::TePapa/$VERSION");

    my $url = URI->new($self->url_base . $path);
    if ($params) {
        for my $p (keys %$params) {
            $url->query_param($p => $params->{$p});
        }
    }
    
    my $req = HTTP::Request->new(
        $method => $url,
        [
            'Accept' => 'application/json; charset=UTF-8',
            'x-api-key'    => $self->key,
        ]
    );

    my $res = $ua->request($req);

    if (!$res->is_success) {
        die "Failed to query Te Papa API: " . $res->status_line . "\n";
    }

    my $json = JSON::MaybeXS->new();
    return $json->decode($res->decoded_content);
}

has 'key' => (
    is       => 'ro',
    required => 1,
);

has 'url_base' => (
    is => 'ro',
    default => 'https://data.tepapa.govt.nz/collection',
);

=head1 TODO

The advanced search interface isn't implemented, as it's a little different to
the others and I don't need it.

=head1 AUTHOR

Robin Sheat, C<< <rsheat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-museum-tepapa at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Museum-TePapa>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Museum::TePapa


You can also look for information at:

=over 4

=item * Source Repository (report bugs here)

L<https://gitlab.com/eythian/museum-tepapa>

=item * RT: CPAN's request tracker (or here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Museum-TePapa>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Museum-TePapa>

=item * Search CPAN

L<https://metacpan.org/release/Museum-TePapa>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Robin Sheat.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007


=cut

1; # End of Museum::TePapa
