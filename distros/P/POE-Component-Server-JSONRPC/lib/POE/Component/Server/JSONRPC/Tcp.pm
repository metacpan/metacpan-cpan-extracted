package POE::Component::Server::JSONRPC::Tcp;
use strict;
use warnings;
use base qw(POE::Component::Server::JSONRPC);

our $VERSION = '0.01';

use POE qw/
    Component::Server::TCP
    Filter::Line
    /;
use JSON::Any;

=head1 NAME

POE::Component::Server::JSONRPC::Tcp - POE tcp based JSON-RPC server

=head2 new

constructor
=cut

sub new {
    my $self = shift->SUPER::new( @_ > 1 ? {@_} : $_[0] );
    return $self;
}

=head2 poe_init_server

Init TCP Server.
=cut

sub poe_init_server {
    my ($self, $kernel, $session, $heap) = @_[OBJECT, KERNEL, SESSION, HEAP];

    my $bind = sub {
        my $method = $_[0];

        return sub {
            my ($kernel, $tcp_session, @args) = @_[KERNEL, SESSION, ARG0..$#_ ];
            #~ $kernel->post( $session->ID, $method, $tcp_session->ID, @args );
            $kernel->post( $session->ID, $method, {content=>$args[0]},$tcp_session->ID, "" );
        };
    };
    $self->{tcp} = POE::Component::Server::TCP->new(
        Port => $self->{Port},
        $self->{Address}     ? ( Address     => $self->{Address} )     : (),
        $self->{Hostname}    ? ( Hostname    => $self->{Hostname} )    : (),
        $self->{Domain}      ? ( Domain      => $self->{Domain} )      : (),
        $self->{Concurrency} ? ( Concurrency => $self->{Concurrency} ) : (),

        ClientInput        => $bind->('input_handler'),
#        ClientConnected    => $bind->('tcp_connect_handler'),
#        ClientDisconnected => $bind->('tcp_disconnect_handler'),
#        ClientError        => $bind->('tcp_client_error_handler'),
#        ClientFlushed      => $bind->('tcp_client_flush_handler'),

        ClientInputFilter => $self->{ClientInputFilter} || POE::Filter::Line->new,
        ClientOutputFilter => $self->{ClientOutputFilter} || POE::Filter::Line->new,

        InlineStates => {
            send => sub {
                my ($client, $data) = @_[ARG0..$#_];
                $client->put($data) if $client;
            },
        },
    );
}

=head2 poe_send

Send TCP response
=cut

sub poe_send {
    my ($kernel,$response, $content) = @_[KERNEL,ARG0..$#_];

    # TCP
    $kernel->post($response => send => $response,$content);
}

1;
