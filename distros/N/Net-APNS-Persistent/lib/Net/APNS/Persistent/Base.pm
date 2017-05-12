package Net::APNS::Persistent::Base;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

use base 'Class::Accessor';

use Net::SSLeay qw(die_now die_if_ssl_error);
use Socket;

__PACKAGE__->mk_accessors(qw(
                                cert
                                key
                                key_type
                                cert_type
                                passwd
                                _host
                                host_production
                                host_sandbox
                                port
                                sandbox
                                __connection
                           ));

my %defaults = (
    key_type => &Net::SSLeay::FILETYPE_PEM,
    cert_type => &Net::SSLeay::FILETYPE_PEM,
   );

=head1 NAME

Net::APNS::Persistent::Base - Base class for Net::APNS::Persistent and Net::APNS::Feedback

=head1 SYNOPSIS

See L<Net::APNS::Persistent> and L<Net::APNS::Feedback>.

=head1 DESCRIPTION

Base methods for L<Net::APNS::Persistent> and L<Net::APNS::Feedback>.

=cut

sub new {
    my ($class, $init_vals) = @_;

    $init_vals ||= {};

    my $self = $class->SUPER::new({

        %defaults,
        
        %{$init_vals}
       });

    # Use TLSv1
    $Net::SSLeay::ssl_version = 10;

    Net::SSLeay::load_error_strings();
    Net::SSLeay::SSLeay_add_ssl_algorithms();
    Net::SSLeay::randomize();
    
    return $self;
}

sub host {
    my $self = shift;

    if (@_ || $self->_host) {
        return $self->_host(@_);
    }

    if ($self->sandbox) {
        return $self->host_sandbox;
    } else {
        return $self->host_production;
    }
}

sub _server_sockadder_in {
    my $self = shift;

    my $ip = inet_aton( $self->host )
      or die "Unable to get address for " . $self->host;

    return sockaddr_in( $self->port, $ip );
}

sub _connection {
    my $self = shift;
    
    my $connection = $self->__connection;

    my ($socket, $ctx, $ssl);
    ($socket, $ctx, $ssl) = @{$connection}
      if $connection;
    
    # TODO: attempt reconnect if the socket is bad
    # at the moment, will just die which is ok since
    # we only promise to raise an exception in the doccs.
    if (!$socket || !$ctx || !$ssl) {
        
        # free any existing resources
        $self->disconnect;
        
        socket( $socket, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
          or die "error creating socket: $!";

        connect( $socket, $self->_server_sockadder_in )
          or die "error connecting socket: $!";

        $ctx = Net::SSLeay::CTX_new()
          or die_now( "failed to create SSL_CTX: $!");

        Net::SSLeay::CTX_set_options( $ctx, &Net::SSLeay::OP_ALL );
        die_if_ssl_error("error while setting ctx options: $!");

        Net::SSLeay::CTX_set_default_passwd_cb( $ctx, sub { $self->passwd } );
        Net::SSLeay::CTX_use_RSAPrivateKey_file( $ctx, $self->key, $self->key_type );
        die_if_ssl_error("error while setting private key: $!");

        Net::SSLeay::CTX_use_certificate_file( $ctx, $self->cert, $self->cert_type );
        die_if_ssl_error("error while setting certificate: $!");

        $ssl = Net::SSLeay::new( $ctx );

        Net::SSLeay::set_fd( $ssl, fileno($socket) );
        Net::SSLeay::connect( $ssl )
            or die_now( "failed ssl connect: $!");

        $connection = [$socket, $ctx, $ssl];
        
        $self->__connection($connection);
    }

    return $connection;
}

sub disconnect {
    my $self = shift;
    
    # go straight to the accessor, we don't
    # want to create a connection simply to
    # disconnect it!
    my $connection = $self->__connection;

    if (!$connection) {
        return 1;
    }

    my ($socket, $ctx, $ssl) = @{$connection};

    CORE::shutdown( $socket, 1 )
        if $socket;
    
    Net::SSLeay::free( $ssl )
        if $ssl;
    
    Net::SSLeay::CTX_free( $ctx )
        if $ctx;
    
    close($socket)
      if $socket;

    $self->__connection(undef);

    return 1;
}

sub _send {
    my ($self, $data) = @_;
    
    my ($socket, $ctx, $ssl) = @{$self->_connection};

    Net::SSLeay::ssl_write_all( $ssl, $data );
    die_if_ssl_error("error writing to ssl connection: $!");

    return 1;
}

sub _read {
    my $self = shift;

    my ($socket, $ctx, $ssl) = @{$self->_connection};

    my $data = Net::SSLeay::ssl_read_all( $ssl );
    die_if_ssl_error("error reading from ssl connection: $!");

    return $data;
}

sub DESTROY {
    my $self = shift;

    $self->disconnect;
}



=head1 SEE ALSO

=over 4

=item L<Net::APNS::Persistent>

=item L<Net::APNS::Feedback>.

=item L<http://github.com/aufflick/p5-net-apns-persistent|GIT Source Repository for this module>

=back

=head1 AUTHOR

Mark Aufflick, E<lt>aufflick@localE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Mark Aufflick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
