package POE::Component::Server::HTTP::KeepAlive::SimpleHTTP;

use strict;
use warnings;

use base qw( POE::Component::Server::HTTP::KeepAlive );

BEGIN {
    *DEBUG = \&POE::Component::Server::HTTP::KeepAlive::DEBUG;
}

################################################
sub conn_ID
{
    my( $self, $c ) = @_;
    return $c->ID;
}

## Get the connection, based on its ID
sub conn_get
{
    my( $self, $id ) = @_;
    my $heap = $self->get_heap;
    if( $heap->{CONNECTIONS}{ $id } 
        and $heap->{CONNECTIONS}{ $id }[ 1 ] ) {
            return $heap->{CONNECTIONS}{ $id }[ 1 ];
    }
    if( $heap->{REQUESTS}{$id}
        and $heap->{REQUESTS}{$id}[2]
        and $heap->{REQUESTS}{$id}[2]->connection ) {
            return $heap->{REQUESTS}{$id}[2]->connection;
    }
    die "Unknown connection id=$id";
}

## Get the connection's wheel, based on its ID
sub conn_wheel
{
    my( $self, $id ) = @_;
    my $heap = $self->get_heap;
    if( $heap->{CONNECTIONS}{ $id } 
        and $heap->{CONNECTIONS}{ $id }[ 0 ] ) {
            return $heap->{CONNECTIONS}{ $id }[ 0 ];
    }
    if( $heap->{REQUESTS}{$id}
        and $heap->{REQUESTS}{$id}[0] ) {
            return $heap->{REQUESTS}{$id}[0];
    }

    die "$heap doesn't have id=$id";
    return;
}


## Close the connection.  Must provoke an on_close()
sub conn_close
{
    my( $self, $c, $id ) = @_;
    $id ||= $self->conn_ID( $c );

    my $heap = $self->get_heap;
    if( $heap->{REQUESTS}{$id}[2] ) {
        DEBUG and warn "Keepalive: close, but request is active";
        return 0;
    }
    unless( $heap->{CONNECTIONS}{$id} ) {
        warn "Keepalive: close but don't have a connection";
        return 0;
    }


    # build a temporary response object
    my $conn = $heap->{CONNECTIONS}{$id}[1];
    my $resp = POE::Component::Server::SimpleHTTP::Response->new(
                $id, $conn
            );

    $POE::Kernel::poe_kernel->call( $self->{http_alias} => 'CLOSE', $resp );
    return 1;
}

## Register an event that is called when the connection is closed by
## the component
sub conn_on_close
{
    my( $self, $c, $id ) = @_;
    $id ||= $self->conn_ID( $c );
    $POE::Kernel::poe_kernel->call( $self->{http_alias}, 'SETCLOSEHANDLER', 
                    $c, $self->{close_event}, $id );
}

1;

__DATA__
