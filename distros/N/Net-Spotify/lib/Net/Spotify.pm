package Net::Spotify;

use warnings;
use strict;

use Net::Spotify::Lookup;
use Net::Spotify::Search;

our $VERSION = '0.03';

sub new {
    my $class = shift;

    my $self = {
        lookup => Net::Spotify::Lookup->new(),
        search => Net::Spotify::Search->new(),
    };

    bless $self, $class;

    return $self;
}

sub lookup {
    my ($self, @parameters) = @_;

    return $self->{lookup}->make_request(@parameters);
}

sub search {
    my ($self, @parameters) = @_;

    return $self->{search}->make_request(@parameters);
}

1;

__END__

=pod

=head1 NAME

Net::Spotify - Perl interface to the Spotify Metadata API

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Net::Spotify;

    my $spotify = Net::Spotify->new();

    # lookup a track
    my $track_xml = $spotify->lookup(
        uri => 'spotify:track:6NmXV4o6bmp704aPGyTVVG'
    );

    # search an artist
    my $artist_xml = $spotify->search(
        'artist',
        q => 'hendrix'
    );

=head1 DESCRIPTION

This module provides a simple interface to the Spotify Metadata API
L<https://developer.spotify.com/technologies/web-api/>.
The API allows to explore Spotify's music catalogue.
It is possible to lookup a specific Spotify URI and retrieve various
information about the resource it represents, and search for artists,
albums and tracks.
The output is in XML format.

=head1 METHODS

=head2 new

Class constructor.

=head2 lookup(uri => $uri [, extras => $extras])

Performs a lookup on a specific Spotify URI.
L<Net::Spotify::Lookup> is used for handling the request.

=head3 Parameters

=over 4

=item $uri

Mandatory, represents the Spotify URI.
Example: C<spotify:artist:4YrKBkKSVeqDamzBPWVnSJ>

=item $extras

Optional, a comma separated list of words that defines the 
detail level in the response.
Allowed values depend on the Spotify URI type.

For C<album>: C<track> and C<trackdetail>
For C<artist>: C<album> and C<albumdetail>
For C<track>: none

=back

=head3 Example

    # lookup an album and retrieve detailed information about all its tracks
    $spotify->lookup(
        uri => 'spotify:album:6G9fHYDCoyEErUkHrFYfs4',
        extras => 'trackdetail'
    );

=head2 search($method, q => $query [, page => $page])

Performs a search.
L<Net::Spotify::Search> is used for handling the request.

=head3 Parameters

=over 4

=item $method

Mandatory, represent the type of search.
Possible values are: C<album>, C<artist>, C<track>.

=item $query

Mandatory, it's the search string.

=item $page

Optional, represent the page of the resultset to return, defaults to 1.

=back

=head3 Example

    # search all the tracks where the track name, artist or album matches the
    # the query string (purple) and return the results in page 2
    $spotify->search(
        'track',
        q => 'purple',
        page => 2
    );

=head1 SEE ALSO

L<Net::Spotify::Service>, L<Net::Spotify::Lookup>, L<Net::Spotify::Search>

=head1 AUTHOR

Edoardo Sabadelli, C<< <edoardo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-spotify at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Spotify>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Spotify

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Spotify>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Spotify>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Spotify>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Spotify/>

=back

=head1 ACKNOWLEDGEMENTS

This product uses a SPOTIFY API but is not endorsed, certified or otherwise 
approved in any way by Spotify.
Spotify is the registered trade mark of the Spotify Group.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Edoardo Sabadelli, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
