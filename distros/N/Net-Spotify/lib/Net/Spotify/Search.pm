package Net::Spotify::Search;

use strict;
use warnings;

use base 'Net::Spotify::Service';

our $VERSION = '0.03';

sub format_request {
    my ($self, $method, %parameters) = @_;

    my $base_url = $self->base_url();
    my $version = $self->version();
    my $format = $self->format();

    my $uri = URI->new("$base_url/search/$version/$method.$format");

    foreach my $key (qw(q page)) {
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

Net::Spotify::Search - Perl interface to the Spotify Metadata API

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Net::Spotify::Search;

    my $search = Net::Spotify::Search->new();

    # search the artist and get detailed information
    # about all the related albums
    my $response = $search->make_request(
        'track',
        q => 'june tune',
        page => 2,
    );

=head1 DESCRIPTION

This module implements the interface to the C<search> service of the Spotify
Metadata API.
It inherits most of the methods from L<Net::Spotify::Service>.

L<https://developer.spotify.com/technologies/web-api/search/>

=head1 METHODS

=head2 format_request

Builds the request used by C<make_request()>.
The URI format is:
[base_url]/search/[version]/[method].[format]?q=[search_term]&page=[page]
Ie. http://ws.spotify.com/search/1/track.xml?q=june%20tune&page=2

Returns an L<HTTP::Request> object.

=head3 Parameters

Parameters are passed from C<make_request()>.
The first is a scalar, and the second a hash.

=over 4

=item type

Represents the type of search. Possible values are:
C<artist>, C<album>, C<track>.
Mandatory.

=item q

The search term.
Mandatory.

=item page

The page of the result set to return. Defaults to 1.
Optional.

=back 

=head1 SEE ALSO

C<Net::Spotify>, C<Net::Spotify::Service>, C<Net::Spotify::Lookup>

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
