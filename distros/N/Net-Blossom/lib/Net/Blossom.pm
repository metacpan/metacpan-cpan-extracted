package Net::Blossom;

use strictures 2;

use Net::Blossom::Client;
use Net::Blossom::ServerList;
use Net::Blossom::URI;

our $VERSION = '0.001001';

sub client {
    my $class = shift;
    return Net::Blossom::Client->new(@_);
}

1;

=pod

=head1 NAME

Net::Blossom - Perl client and protocol support for Blossom

=head1 SYNOPSIS

    use Net::Blossom;

    my $client = Net::Blossom->client(
        server => 'https://cdn.example.com',
    );

    my $response = $client->get_blob($sha256);

=head1 DESCRIPTION

C<Net::Blossom> is the main entry point for the Perl implementation of the
Blossom protocol. The distribution provides value objects for Blossom protocol
data, BUD-11 authorization token creation, Blossom URI handling, server-list
handling, and an HTTP client. Server-side support is provided separately by
L<Net::Blossom::Server>.

This module intentionally keeps a small surface. Most callers should use
C<client> or construct C<Net::Blossom::Client> directly.

=head1 METHODS

=head2 client

    my $client = Net::Blossom->client(%args);

Constructs and returns a C<Net::Blossom::Client>. Arguments are passed directly
to C<Net::Blossom::Client-E<gt>new>.

=head1 SEE ALSO

L<Net::Blossom::Client>, L<Net::Blossom::AuthToken>,
L<Net::Blossom::BlobDescriptor>, L<Net::Blossom::ServerList>,
L<Net::Blossom::URI>, L<Net::Blossom::Server>

=cut
