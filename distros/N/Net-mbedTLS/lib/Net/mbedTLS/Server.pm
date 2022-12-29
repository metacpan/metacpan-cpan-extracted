package Net::mbedTLS::Server;

use strict;
use warnings;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::mbedTLS::Server - Class representing a TLS server

=head1 SYNOPSIS

    my $listener = IO::Socket::INET->new(
        Listen => 1,
        LocalAddr => 'localhost:443',
    ) or die;

    my $peer = $listener->accept();

    my $tls = Net::mbedTLS->new()->create_server(
        $peer,

        key_and_cert => [ $key, @cert_chain ],

        servername_cb => sub {
            return $key_and_certs_pem;
        },
    );

=cut

=head1 DESCRIPTION

Subclass of L<Net::mbedTLS::Connection>.

=cut

#----------------------------------------------------------------------

use parent 'Net::mbedTLS::Connection';

use Net::mbedTLS::Server::SNICallbackCtx;

sub DESTROY {
    my $self = shift;

    $self->_DESTROY();

    $self->SUPER::DESTROY();
}

1;
