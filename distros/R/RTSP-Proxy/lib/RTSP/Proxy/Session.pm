package RTSP::Proxy::Session;

our $VERSION = '0.02';

use Moose;

use Carp qw/croak/;
use RTSP::Client '0.03';

has id => (
    is => 'rw',
);

has rtsp_client => (
    is => 'rw',
    isa => 'RTSP::Client',
    lazy => 1,
    builder => 'build_rtsp_client',
);

has rtsp_client_opts => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    lazy => 1,
);

# options passed to child media transport servers
has transport_handler_opts => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    lazy => 1,
);

has media_uri => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has transport_handler => (
    is => 'rw',
    does => 'RTSP::Proxy::Transport',
    handles => [qw/handle_packet/],
    lazy => 1,
    builder => 'build_transport_handler',
);

has transport_handler_class => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has transport_pid => (
    is => 'rw',
);

has client_address => (
    is => 'rw',
    required => 1,
);

has client_port_start => (
    is => 'rw',
);

has client_port_end => (
    is => 'rw',
);

######

sub DEMOLISH {
    my $self = shift;
    $self->cleanup_transport_handler_server;
}

sub build_rtsp_client {
    my $self = shift;
    my $rc = RTSP::Client->new_from_uri(
        uri => $self->media_uri,
        %{$self->rtsp_client_opts},
    );
    return $rc;
}

sub build_transport_handler {
    my $self = shift;

    my $transport_handler_class = $self->transport_handler_class;        
    my $transport_handler = $transport_handler_class->new($self->transport_handler_opts);
    
    $transport_handler->session($self);
    
    return $transport_handler;
}

# fork off a process and run proxy for media transport
sub run_transport_handler_server {
    my $self = shift;
    
    return if $self->transport_pid;
    
    $self->transport_pid(fork);
    return if $self->transport_pid;
    
    # this is now the child process. start up the server and run it
    $self->transport_handler->log(3, "Child $$ starting transport server");
    my $server = $self->transport_handler;
    $server->run;
}

sub cleanup_transport_handler_server {
    my $self = shift;
    
    return unless $self->transport_pid;
    
    # kill everything in the process group
    warn "Killing child transport proxy\n";
    {
        local $SIG{TERM} = 'IGNORE';
        kill TERM => -$$;   # process group
    }
}


__PACKAGE__->meta->make_immutable;
