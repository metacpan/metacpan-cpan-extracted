package Museum::MetropolitanMuseumArt;

use 5.34.0;
use strictures 2;

use JSON::MaybeXS;
use LWP::UserAgent;
use Moo;
use URI::QueryParam;

use namespace::clean;

=head1 NAME

Museum::MetropolitanMuseumArt - A simple interface to the Metropolitan Museum of Art's API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Provides access to the object-related endpoints from the Metropolitan Museum's
API. See L<https://metmuseum.github.io/#objects> for the API information.

    use Museum::MetropolitanMuseumArt;

    my $m = Museum::MetropolitanMuseumArt->new();
    # Returns an arrayref of IDs. Dies if there's an error.
    my $new_objects->$m->get_objects(date => '2023-01-01');
    if (@$new_objects) {
        # A hashref containing the object data
        my $object = $m->get_object($new_objects->[0]);
        say $object->{title};
    }

Note: The Met Museum requests a rate-limit of 80 requests per second,
please stick to that.

=head1 METHODS

=head2 get_objects

Gets a list of all or a subset of object IDs from the API. Note that this can
be a fair bit of data (nearly half a million entries at the time of writing.)

Return a hashref.

Parameters:

=over 4

=item date

Corresponds to C<metadataDate> in the API.

=item departments

An arrayref of department IDs to restrict the results to.

=back

Dies if something goes wrong.


=cut

sub get_objects {
    my ( $self, %params ) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent("Museum::MetropolitanMuseumArt/$VERSION");

    my $url = URI->new( $self->url_base . '/objects' );
    if ( $params{date} ) {
        $url->query_param( metadataDate => $params{date} );
    }
    if ( $params{departments} && $params{departments}->@* ) {
        $url->query_param( departmentIds => join( '|', $params{departments}->@* ) );
    }

    my $req = HTTP::Request->new(
        GET => $url,
        [
            'Accept' => 'application/json; charset=UTF-8',
        ]
    );

    my $res = $ua->request($req);

    if ( !$res->is_success ) {
        die "Failed to query Metropolitan Museum 'objects' API: " . $res->status_line . "\n";
    }

    my $json = JSON::MaybeXS->new();
    my $content = $json->decode( $res->decoded_content );
    return $content->{objectIDs};
}

=head2 get_object

Fetches the object detail, the only parameter is the object ID.

=cut

sub get_object {
    my ( $self, $object_id ) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent("Museum::MetropolitanMuseumArt/$VERSION");
    my $url = $self->url_base . '/objects/' . $object_id;
    my $req = HTTP::Request->new(
        GET => $url,
        [
            'Accept' => 'application/json; charset=UTF-8',
        ]
    );

    my $res = $ua->request($req);

    if ( !$res->is_success ) {
        die "Failed to query Metropolitan Museum 'object' API: " . $res->status_line . "\n";
    }

    my $json = JSON::MaybeXS->new();
    return $json->decode( $res->decoded_content );
}

has 'url_base' => (
    is      => 'ro',
    default => 'https://collectionapi.metmuseum.org/public/collection/v1',
);

=head1 AUTHOR

Robin Sheat, C<< <rsheat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-museum-metropolitanmuseumart at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Museum-MetropolitanMuseumArt>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO

This only supports the endpoints that I immediately needed, there are a few others
(in particular search) that aren't currently supported.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Museum::MetropolitanMuseumArt


You can also look for information at:

=over 4

=item * Source Repository (report bugs here)

L<https://gitlab.com/eythian/museum-metropolitanmuseumart>

=item * RT: CPAN's request tracker (or here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Museum-MetropolitanMuseumArt>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Museum-MetropolitanMuseumArt>

=item * Search CPAN

L<https://metacpan.org/release/Museum-MetropolitanMuseumArt>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Robin Sheat.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007


=cut

1;    # End of Museum::MetropolitanMuseumArt
