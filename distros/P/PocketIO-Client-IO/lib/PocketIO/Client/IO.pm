package PocketIO::Client::IO;

use strict;
use warnings;
use AnyEvent::PocketIO::Client;
use Scalar::Util ();

our $VERSION = '0.01';

sub connect {
    my ( $clsas, $url ) = @_;
    my $client = AnyEvent::PocketIO::Client->new;
    my ( $server, $port ) = $url =~ m{https?://([.\w]+)(?::(\d+))?};

    $port ||= 80;

    my $socket;
    my $cv = AnyEvent->condvar;

    $client->handshake( $server, $port, sub {
        my ( $error, $self, $sesid, $hbtimeout, $contimeout, $transports ) = @_;

        if ( $error ) {
            Carp::carp( $error->{ message } );
            $cv->send;
            return;
        }

        $self->on('open' => sub {
            $cv->send;
        });

        $self->open();

        return;
    } );

    $cv->wait;

    return unless $client->conn;

    $socket = $client->conn->socket;

    bless $socket, 'PocketIO::Socket::ForClient';

    $socket->{ _client } = $client;
    Scalar::Util::weaken( $socket->{ _client } );

    return $socket;
}


package PocketIO::Socket::ForClient;

use base 'PocketIO::Socket';

sub on {
    my $self = shift;
    my ( $name, $cb ) = @_;

    if ( $name eq 'connect' and $cb ) {
        my $w; $w = AnyEvent->timer( after => 0, interval => 1, cb => sub {
            if ( $self->{ _client }->is_opened ) {
                undef $w;
                $cb->( $self );
            }
        } );
    }
    else {
        $self->SUPER::on( @_ );
    }

}

1;

=pod

=head1 NAME

PocketIO::Client::IO - simple pocketio client

=head1 SYNOPSIS

    use PocketIO::Client::IO;
    
    my $socket = PocketIO::Client::IO->connect("http://localhost:3000/");
    # $socket is a PocketIO::Socket object.
    
    my $cv = AnyEvent->condvar;
    my $w  = AnyEvent->timer( after => 5, cb => $cv );
    
    $socket->on( 'message', sub {
        say $_[1];
    } );
    
    $socket->on( 'connect', sub {
        $socket->send('Parumon!');
        $socket->emit('hello', "perl");
    } );
    
    $cv->wait;

=head1 DESCRIPTION

Simple Socket.IO client using AnyEvent::PocketIO::Client.

This is B<beta> version. APIs will be changed.

Currently acceptable transport id is B<websocket> only.

If you want to controll client action more detail,
please see to L<AnyEvent::PocketIO::Client>.

=head1 METHODS

=head2 connect

    $socket = PocketIO::Client::IO->connect( $url );

Handshakes and connects to C<$url>, then returns a C<PocketIO::Socket::ForClient>
object which inherits L<PocketIO::Socket>.

=head1 SEE ALSO

L<AnyEvent::PocketIO::Client>, L<PocketIO>, L<PcketIO::Socket>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

