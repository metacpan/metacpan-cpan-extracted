package Net::Spotify::Lookup;

use strict;
use warnings;

use base 'Net::Spotify::Service';

our $VERSION = '0.03';

sub format_request {
    my ($self, %parameters) = @_;

    my $base_url = $self->base_url();
    my $version = $self->version();

    my $uri = URI->new("$base_url/lookup/$version/");

    foreach my $key (qw(uri extras)) {
        if (exists $parameters{$key} && $parameters{$key}) {
            $uri->query_param($key, $parameters{$key});
        }
    }

    return HTTP::Request->new('GET', $uri);
}

1;

__END__

=pod

=head1 NAME

Net::Spotify::Lookup - Perl interface to the Spotify Metadata API

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Net::Spotify::Lookup;

    my $lookup = Net::Spotify::Lookup->new();

    # lookup the artist and get detailed information
    # about all the related albums
    my $response = $lookup->make_request(
        uri => 'spotify:artist:4YrKBkKSVeqDamzBPWVnSJ',
        extras => 'albumdetail',
    );

=head1 DESCRIPTION

This module implements the interface to the C<lookup> service of the Spotify
Metadata API.
It inherits most of the methods from L<Net::Spotify::Service>.

L<https://developer.spotify.com/technologies/web-api/lookup/>

=head1 METHODS

=head2 format_request

Builds the request used by C<make_request()>.
The URI format is:
[base_url]/lookup/[version]/?uri=[spotify_uri]&extras=[extras]
Ie. http://ws.spotify.com/lookup/1/?uri=spotify:artist:4YrKBkKSVeqDamzBPWVnSJ&extras=albumdetail

Returns an L<HTTP::Request> object.

=head3 Parameters

Parameters are passed as a hash from C<make_request()>.

=over 4

=item uri

Represents the Spotify URI to lookup.
Mandatory.
Ie. C<spotify:artist:4YrKBkKSVeqDamzBPWVnSJ>

=item extras

A comma-separated list of words that defines the detail level
expected in the response.
Optional.
Ie. C<albumdetail>

=back 

=head1 SEE ALSO

C<Net::Spotify>, C<Net::Spotify::Service>, C<Net::Spotify::Search>

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
