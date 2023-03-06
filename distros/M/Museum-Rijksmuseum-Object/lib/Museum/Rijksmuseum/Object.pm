package Museum::Rijksmuseum::Object;

use strictures 2;

use Carp;
use JSON::MaybeXS;
use LWP::UserAgent;
use Moo;
use URI;
use URI::Encode qw( uri_encode );
use URI::QueryParam;

use namespace::clean;

=head1 NAME

Museum::Rijksmuseum::Object - Access the Rijksmuseum object metadata API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Access the collection, collection details, and collection image endpoints of the Rijksmuseum "Rijksdata" API.

    use Museum::Rijksmuseum::Object;

    my $api           = Museum::Rijksmuseum::Object->new( key => 'abc123xyz', culture => 'en' );
    my $search_result = $api->search( involvedMaker => 'Rembrandt van Rijn' );
    die $search_result->{error} if $search_result->{error};
    print "Results: $search_result->{count}\n";
    for my $item ( $search_result->{artObjects}->@* ) {
        print "Id: $item->{id}\n";
    }

Refer to the L<Rijksmuseum API documentation|https://data.rijksmuseum.nl/object-metadata/api/>
for information on query and response formats. Be aware that the API expects
camelCase on its parameters and this module follows this convention.

=head1 SUBROUTINES/METHODS

=head2 new

    my $api = Museum::Rijksmuseum::Object->new(
        key     => 'abc123xyz',    # the API key supplied by the Rijksmuseum
        culture => 'en',           # the 'culture' parameter, determines the
                                   # language for searching and results
    );

Creates a new object instance. The C<key> and C<culture> parameters are required.

=cut

=head2 search

    my $result = $api->search(
        p       => 3,            # page 3
        ps      => 10,           # 10 results per page
        q       => 'vermeer',    # a general search term
        imgonly => 1,            # image only?
    );

Searches the collection. See the API documentation for parameter details.

=cut

sub search {
    my ( $self, %params ) = @_;

    my $url = $self->_build_url( {}, \%params );
    return $self->_fetch_url($url);
}

=head2 fetch

    my $result = $api->fetch('SK-C-5');

Fetches an individual item from the collection. The parameter is the
C<objectNumber> as returned by the L<search> call.

=cut

sub fetch {
    my ( $self, $object_number ) = @_;

    carp "An object number must be provided to 'fetch'" unless defined $object_number;
    my $url = $self->_build_url( { object_number => $object_number }, {} );
    return $self->_fetch_url($url);
}

=head2 image_info

    my $result = $api->image_info('SK-C-5');

Fetches the information required to build the image tiles for a particular
C<objectNumber>.

=cut

sub image_info {
    my ( $self, $object_number ) = @_;

    carp "An object number must be provided to 'image_info'" unless defined $object_number;
    my $url = $self->_build_url(
        {
            object_number => $object_number,
            tiles         => 1,
        },
        {}
    );
    return $self->_fetch_url($url);
}

sub _build_url {
    my ( $self, $path, $params ) = @_;

    # Determine which URL form we need
    my $url;
    if ( $path->{tiles} ) {
        $url = sprintf(
            'https://www.rijksmuseum.nl/api/%s/collection/%s/tiles',
            uri_encode( $self->culture ),
            uri_encode( $path->{object_number} )
        );
    } elsif ( $path->{object_number} ) {
        $url = sprintf(
            'https://www.rijksmuseum.nl/api/%s/collection/%s',
            uri_encode( $self->culture ),
            uri_encode( $path->{object_number} )
        );
    } else {
        $url =
          sprintf( 'https://www.rijksmuseum.nl/api/%s/collection', uri_encode( $self->culture ) );
    }
    $url = URI->new($url);

    # Add query parameters
    $url->query_param( key => $self->key );
    if ($params) {
        for my $p ( keys %$params ) {
            $url->query_param( $p => $params->{$p} );
        }
    }

    return $url->as_string;
}

sub _fetch_url {
    my ( $self, $url ) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent("Museum::Rijksmuseum::Object/$VERSION");

    my $req = HTTP::Request->new( GET => $url );

    my $res = $ua->request($req);

    if ( $res->is_success ) {
        my $json = JSON::MaybeXS->new( utf8 => 1 );
        return $json->decode( $res->content );
    } else {
        return { error => $res->status_line };
    }
}

=head1 ATTRIBUTES

=head2 key

The API key provided by the Rijksmuseum.

=cut

has key => (
    is       => 'rw',
    required => 1,
);

=head2 culture

The 'culture' that the API will return data to you in, and perform searches in.
Typically 'en' or 'nl'.

=cut

has culture => (
    is       => 'rw',
    required => 1
);

=head1 AUTHOR

Robin Sheat, C<< <rsheat at cpan.org> >>

=head1 TODO

=over 4

=item Make a heavier interface

At the moment this is a very thin interface over the Rijksmuseum API. It could
be improved by having helpers to do things, for example optionally
automatically fetching and stitching images.

=back 

=cut

=head1 BUGS

Please report any bugs or feature requests to C<bug-museum-rijksmuseum-object at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Museum-Rijksmuseum-Object>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Alternately, use the tracker on the repository page at L<https://gitlab.com/eythian/museum-rijksmuseum-object>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Museum::Rijksmuseum::Object


You can also look for information at:

=over 4

=item * Repository page (report bugs here)

L<https://gitlab.com/eythian/museum-rijksmuseum-object>

=item * RT: CPAN's request tracker (or here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Museum-Rijksmuseum-Object>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Museum-Rijksmuseum-Object>

=item * Search CPAN

L<https://metacpan.org/release/Museum-Rijksmuseum-Object>


=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Robin Sheat.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Museum::Rijksmuseum::Object
