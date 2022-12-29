package Net::mbedTLS::Client;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::mbedTLS::Client - Class representing a TLS client

=head1 SYNOPSIS

    my $socket = IO::Socket::INET->new('perl.com:443') or die;

    my $tls = Net::mbedTLS->new()->create_client(
        $socket,
        servername => 'perl.com',
    );

=cut

=head1 DESCRIPTION

Subclass of L<Net::mbedTLS::Connection>.

=cut

#----------------------------------------------------------------------

use parent 'Net::mbedTLS::Connection';

1;
