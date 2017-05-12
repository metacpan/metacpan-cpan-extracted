package Net::Spotify::Service;

use strict;
use warnings;

use Carp ();
use LWP::UserAgent ();
use URI ();
use URI::QueryParam ();

our $VERSION = '0.03';

sub new {
    my $class = shift;
    $class = ref $class || $class || __PACKAGE__;

    my $self = {
        ua => LWP::UserAgent->new(
            agent => 'Net::Spotify/' . $VERSION,
            env_proxy => 1,
        ),
        base_url => 'http://ws.spotify.com',
        version => '1',
        format => 'xml',
    };

    bless $self, $class;

    return $self;
}

sub base_url {
    my $self = shift;

    return $self->{base_url};
}

sub format {
    my $self = shift;

    return $self->{format};
}

sub format_request {
    Carp::croak('format_request() is not implemented.');
}

sub make_request {
    my ($self, @parameters) = @_;

    my $request = $self->format_request(@parameters);

    my $ua = $self->ua();

    my $response = $ua->request($request);

    if ($response->is_success) {
        return $response->content;
    }
    else {
        return $response->status_line;
    }
}

sub ua {
    my $self = shift;

    return $self->{ua};
}

sub version {
    my $self = shift;

    return $self->{version};
}

1;

__END__

=pod

=head1 NAME

Net::Spotify::Service - Perl interface to the Spotify Metadata API

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    # in your subclass
    use base 'Net::Spotify::Service';

    # the only required method to define in the subclass
    # is format_request, which should return an HTTP::Request
    # object
    sub format_request {
        my ($self, @parameters) = @_;

        # build the URI here
        my $uri = URI->new( ... );

        return HTTP::Request->new('GET', $uri);
    }

=head1 DESCRIPTION

This module is not intended to be used alone, but as a base for
subclasses that implement a specific Spotify service.
The two currently available services are C<lookup> and C<search>.

L<https://developer.spotify.com/technologies/web-api/>.

=head1 METHODS

=head2 new

Class constructor.

=head2 base_url

Accessor for the base URL of the Spotify API endpoint.
Returns C<http://ws.spotify.com>.

=head2 format

Accessor for the format of the responses.
Currently only XML is supported and is only used
by the C<search> service.
Returns C<xml>.

=head2 format_request

Builds the request used by C<make_request()>.
This method must be defined in the subclasses.
It must return an L<HTTP::Request> object.

=head3 Parameters

=over 4

=item @parameters

All the parameters passed from C<make_request()>.

=back

=head2 make_request

Makes the real request to the Spotify Metadata API and
handles the response.
Returns the XML content in case of success or the error code and string
in case of error.

=head3 Parameters

=over 4

=item @parameters

The parameters that must be parsed and used to build the request.
See C<format_request()> defined in the subclasses.

=back

=head2 ua

Accessor to the L<LWP::UserAgent> object used
for making the requests.

=head2 version

Accessor to the Spotify service version, currently '1'.

=head1 SEE ALSO

C<Net::Spotify>, C<Net::Spotify::Lookup>, C<Net::Spotify::Search>

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
