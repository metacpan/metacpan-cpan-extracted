package Proc::Safetynet::RpcServer::Unix;
use strict;
use warnings;

use Proc::Safetynet::POEWorker;
use base qw/Proc::Safetynet::POEWorker/;

use Carp;
use Data::Dumper;

use POE::Kernel;
use POE::Session;
use Socket;
use POE::Wheel::SocketFactory;
use POE::Wheel::ReadWrite;
use UNIVERSAL::require;


sub initialize {
    my $self        = $_[OBJECT];
    # add states
    $_[KERNEL]->state( '_child'                 => $self );
    $_[KERNEL]->state( 'server_accepted'        => $self );
    $_[KERNEL]->state( 'server_error'           => $self );
    # initialize socket
    {
        my $t = $self->options->{'socket'} || '';
        my ($rendezvous) = ($t =~ /^(.*)$/);
        unlink $rendezvous if -e $rendezvous;
        $self->{server} = POE::Wheel::SocketFactory->new(
            SocketDomain => PF_UNIX,
            BindAddress  => $rendezvous,
            SuccessEvent => 'server_accepted',
            FailureEvent => 'server_error',
        );
    }
    # check supervisor
    {
        (defined $self->options->{'supervisor'})
            or confess "supervisor not defined";
        $self->{supervisor} = $self->options->{'supervisor'};
    }
    # check session class
    {
        (defined $self->options->{'session_class'})
            or confess "session_class not defined";
        $self->{session_class} = $self->options->{'session_class'};
        # load the module right away, we need this for communicating with clients
        $self->{session_class}->require
            or confess "unable to load session class: ".$self->{session_class}.": $!";
    }
}


# The server encountered an error while setting up or perhaps while
# accepting a connection.  Register the error and shut down the server
# socket.  This will not end the program until all clients have
# disconnected, but it will prevent the server from receiving new
# connections.

sub server_error {
    my ( $self, $syscall, $errno, $error ) = @_[ OBJECT, ARG0 .. ARG2 ];
    $error = "Normal disconnection." unless $errno;
    my $msg = "Server socket encountered $syscall error $errno: $error\n";
    warn $msg;
    delete $self->{server};
    $_[KERNEL]->post( $self->{supervisor}, 'bcast_system_error', $msg )
        or carp "unable to post supervisor bcast message";
    
}

# The server accepted a connection.  Start another session to process
# data on it.

sub server_accepted {
    my $self            = $_[OBJECT];
    my $client_socket   = $_[ARG0];
    $self->{session_class}->spawn( 
        supervisor  => $self->{supervisor},
        socket      => $client_socket
    );
}



sub _child {
    # do nothing for now
}

1;

__END__
