package Supervisor::RPC::Client;

our $VERSION = '0.02';
our $DEBUG = 0 unless defined $DEBUG;

use IO::Socket;

use Supervisor::Class
  version   => $VERSION,
  base      => 'Supervisor::Base',
  codec     => 'JSON',
  accessors => 'id server',
  constants => 'HASH ARRAY STOPPED :rpc',
  messages => {
      server_connect => "unable to connect to %s on port %s",
      rpc_error      => "server error: %s, message: %S",
      json_encode    => "unable to encode the packet",
      json_decode    => "unable to decode the packet",
      network        => "a network communication error has occured"
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub start {
    my ($self, $name) = @_;

    my $result;
    my $params = {
        name => $name
    };

    $result = $self->_call('start_process', $params);

    return $result;

}

sub stop {
    my ($self, $name) = @_;

    my $result;
    my $params = {
        name => $name
    };

    $result = $self->_call('stop_process', $params);

    return $result;

}

sub reload {
    my ($self, $name) = @_;

    my $result;
    my $params = {
        name => $name
    };

    $result = $self->_call('reload_process', $params);

    return $result;

}

sub status {
    my ($self, $name) = @_;

    my $result;
    my $params = {
        name => $name
    };

    $result = $self->_call('stat_process', $params);

    return $result;

}

sub stop_supervisor {
    my ($self) = @_;

    my $result;
    
    $result = $self->_call('stop_supervisor');

    return $result;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    my $port;
    my $host;
    my $ex = 'supervisor.rpc.client.init';

    $self->{id} = 0;
    $self->{config} = $config;

    $port = $self->config('-port') || DEFAULT_PORT;
    $host = $self->config('-host') || DEFAULT_ADDRESS;

    $self->{server} = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerPort => $port,
        PeerAddr => $host
    ) or $self->throw_msg($ex, 'server_connect', $host, $port);

    return $self;

}

sub _call {
    my ($self, $method, $params) = @_;

    my $packet;
    my $request;
    my $response;
    my $id = $self->{id}++;
    my $ex = 'supervisor.rpc.client._call.';

    eval {

        $request = encode(
            {
                jsonrpc => JSONRPC,
                method  => $method,
                params  => $params,
                id      => $id,
            }
        );

    }; if ($@) {

        $self->throw_msg($ex . 'json_encode', 'json_encode');

    }

    eval {

        $self->server->printf("%s\012\015", $request);
        $self->server->recv($packet, 1024);

    }; if ($@) {
        
        $self->throw_msg($ex . 'network', 'network');

    }

    eval {

        $response = decode($packet);

     }; if ($@) {

        $self->throw_msg($ex . 'json_decode', 'json_decode');

    }

    if (defined($response->{error})) {

        $self->throw_msg(
            $ex . 'rpc_error',
            'rpc_error', 
            $response->{error}->{code},
            $response->{error}->{message}
        );

    }

    return $response->{result};

}

1;

__END__

=head1 NAME

Supervisor::RPC::Client - The client interface to the Supervisors environment

=head1 SYNOPSIS

 use Supervisor::RPC::Client;

 my $rpc = Supervisor::RPC::Client->new()
 my $result = $rpc->start('sleeper');

=head1 DESCRIPTION

This is the client module for external access to the Supervisor. It provides
methods to start/stop/reload and retrieve the status of managed processes.

=head1 METHODS

=over 4

=item new

This initilaize the module and can take two parameters.

 Example:

     my $rpc = Supervisor::RPC::Client->new(
        -port    => 9505,
        -address => 'localhost'
     };

=item start

This method will start a managed process. It takes one parameter, the name
of the process, and returns "started" if successful.

 Example:

     my $result = $rpc->start('sleeper');

=item stop

This method will stop a managed process. It takes one parameter, the name of
the process, and returns "stopped" if successful.

 Example:

     my $result = $rpc->stop('sleeper');

=item status

This method will do a "stat" on a managed process. It takes one parameter,
the name of the process, and returns "alive" if the process is running or 
"dead" if the process is not.

=item reload

This method will attempt to "reload" a managed process. It takes one parameter,
the name of the process. It will return "reloaded".

 Example:

     my $result = $rpc->reload('sleeper');

=back

=head1 SEE ALSO

 Supervisor
 Supervisor::Base
 Supervisor::Class
 Supervisor::Constants
 Supervisor::Controller
 Supervisor::Log
 Supervisor::Process
 Supervisor::ProcessFactory
 Supervisor::Session
 Supervisor::Utils
 Supervisor::RPC::Server
 Supervisor::RPC::Client

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.
=cut
