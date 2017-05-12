package Supervisor::RPC::Server;

our $VERSION = '0.02';
our $DEBUG = 0 unless defined $DEBUG;

use POE;
use Socket;
use Set::Light;
use POE::Wheel::ReadWrite;
use POE::Wheel::SocketFactory;

use Supervisor::Class
  version   => $VERSION,
  base      => 'Supervisor::Session',
  codec     => 'JSON',
  utils     => 'params',
  accessors => 'supervisor client listener host port methods',
  constants => 'HASH ARRAY :rpc',
  messages => {
      'connection_failed' => "the client connection failed with %s, reason %s",
      'client_error'      => "the client experienced error %s, reason %s",
      'client_connect'    => "a connection from %s on port %s",
      'rpc_method'        => "the rpc method \"%s\" is unknown",
      'rpc_version'       => "this json-rpc version \"%s\", is not supported",
      'rpc_format'        => "this json-rpc format is not supported",
      'rpc_batch'         => "the usage of json-rpc batch mode is not supported",
      'rpc_notify'        => "the usage of json-rpc notifications is not supported",
  }
;

# ----------------------------------------------------------------------
# POE Events
# ----------------------------------------------------------------------

sub startup {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    $self->{listener} = POE::Wheel::SocketFactory->new(
        BindAddress    => $self->config('Address') || DEFAULT_ADDRESS,
        BindPort       => $self->config('Port') || DEFAULT_PORT,
        SocketType     => SOCK_STREAM,
        SocketDomain   => AF_INET,
        SocketProtocol => 'tcp',
        Listen         => 1,
        Reuse          => 1,
        SuccessEvent   => '_client_connected',
        FailureEvent   => '_client_connection_failed'
    );

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub response {
    my ($kernel, $self, $data) = @_[KERNEL,OBJECT,ARG0];

    $kernel->yield('_jsonrpc_result', $data->{id}, $data->{result}, $data->{client});

}

# ----------------------------------------------------------------------
# RPC Events
# ----------------------------------------------------------------------

sub stop_process {
    my ($kernel, $self, $id, $args) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $supervisor = $self->supervisor;
    my $data = {
        name   => $args->{name},
        id     => $id,
        client => $self->client,
        rpc    => $self->session->ID
    };

    $kernel->post($supervisor, 'stop_process', $data);

}

sub stat_process {
    my ($kernel, $self, $id, $args) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $supervisor = $self->supervisor;
    my $data = {
        name   => $args->{name},
        id     => $id,
        client => $self->client,
        rpc    => $self->session->ID
    };

    $kernel->post($supervisor, 'stat_process', $data);

}

sub start_process {
    my ($kernel, $self, $id, $args) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $supervisor = $self->supervisor;
    my $data = {
        name   => $args->{name},
        id     => $id,
        client => $self->client,
        rpc    => $self->session->ID
    };

    $kernel->post($supervisor, 'start_process', $data);

}

sub reload_process {
    my ($kernel, $self, $id, $args) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $supervisor = $self->supervisor;
    my $data = {
        name   => $args->{name},
        id     => $id,
        client => $self->client,
        rpc    => $self->session->ID
    };

    $kernel->post($supervisor, 'reload_process', $data);

}

sub stop_supervisor {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $supervisor = $self->supervisor;
    my $data = {
        client => $self->client,
        rpc    => $self->session->ID
    };

    $kernel->post($supervisor, 'stop_supervisor', $data);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _initialize {
    my ($self, $kernel, $session) = @_;

    # communications to the supervisor

    my @methods = (
        'stop_process',
        'stat_process',
        'start_process',
        'reload_process',
        'stop_supervisor'
    );

    # communications from the supervisor

    $kernel->state('response', $self);

    # RPC generated events

    $kernel->state('stop_process', $self);
    $kernel->state('stat_process', $self);
    $kernel->state('start_process', $self);
    $kernel->state('reload_process', $self);
    $kernel->state('stop_supervisor', $self);

    # internal communications

    $kernel->state('_client_error', $self);
    $kernel->state('_jsonrpc_error', $self);
    $kernel->state('_jsonrpc_result', $self);
    $kernel->state('_client_message', $self);
    $kernel->state('_client_connected', $self);
    $kernel->state('_client_connection_failed', $self);

    $self->{methods}    = Set::Light->new(@methods);
    $self->{supervisor} = $self->config('Supervisor');

}

sub _cleanup {
    my ($self, $kernel, $session) = @_;

    $self->log->info('Shutting down');

    if (my $wheel = $self->client) {

        delete $self->{wheel};

    }

    if (my $listener = $self->listener) {

        delete $self->{listener};

    }

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _client_connected {
    my ($kernel, $self, $socket, $peeraddr, $peerport, $wheel_id) = 
      @_[KERNEL,OBJECT,ARG0 .. ARG3];

    $self->{client} = POE::Wheel::ReadWrite->new(
        Handle     => $socket,
        InputEvent => '_client_message',
        ErrorEvent => '_client_error'
    );

    $self->{host} = gethostbyaddr($peeraddr, AF_INET);
    $self->{port} = $peerport;

    $self->log->info($self->message('client_connect', $self->host, $self->port));
        
}

sub _client_message {
    my ($kernel, $self, $input, $wheel_id) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $ref;
    my $error;
    my $request;
    my $parms = [];
    my $err = 'server._client_message.';
    my $supervisor = $self->supervisor;

    eval {

        $request = decode($input);

        if (ref($request) eq ARRAY) {

            $self->throw_msg($err . 'rpc_batch', 'rpc_batch');

        }
 
        if (ref($request) ne HASH) {

            $self->throw_msg($err . 'rpc_format', 'rpc_format');

        }
    
        if (!defined($request->{jsonrpc}) or
            ($request->{jsonrpc} ne JSONRPC)) {

            $self->throw_msg($err . 'rpc_version', 'rpc_version');

        }

        if (! exists($request->{id})) {

            $self->throw_msg($err . 'rpc_notify', 'rpc_notify');

        }

        if (exists($request->{params})) {

            if (ref($request->{params}) eq ARRAY) {

                $self->throw_msg($err . 'rpc_format', 'rpc_format');

            }

            $parms = params($request->{params});

        }

        if ((defined($request->{method})) and 
            ($self->methods->has($request->{method}))) {

            $kernel->yield($request->{method}, $request->{id}, $parms);

        } else {

            $self->throw_msg($err . 'rpc_method', 'rpc_method', $request->{method});

        }

    }; if (my $ex = $@) {

        my $ref = ref($ex);

        if ($ref) {

            if ($ex->isa('Badger::Exception')) {

                my $type = $ex->type;
                my $info = $ex->info;

                if ($type eq ($err . 'rpc_method')) {
                    
                    $kernel->yield('_jsonrpc_error', $request->{id}, ERR_METHOD, $info, $self->client);

                } elsif ($type eq ($err . 'rpc_version')) {

                    $kernel->yield('_jsonrpc_error', $request->{id}, ERR_REQ, $info, $self->client);

                } elsif ($type eq ($err . 'rpc_format')) {

                    $kernel->yield('_jsonrpc_error', $request->{id}, ERR_PARSE, $info, $self->client);

                } elsif ($type eq ($err . 'rpc_batch')) {

                    $kernel->yield('_jsonrpc_error', $request->{id}, ERR_INTERNAL, $info, $self->client);

                } elsif ($type eq ($err . 'rpc_notify')) {

                    $kernel->yield('_jsonrpc_error', $request->{id}, ERR_INTERNAL, $info, $self->client);
                    
                }

            } else {

                $kernel->yield('_jsonrpc_error', $request->{id}, ERR_SERVER, "Server error", $self->client);

            }

        } else {

            if ($ex =~ m/JSON/i) {

                my $text = $self->message('rpc_format');
                $kernel->yield('_jsonrpc_error', $request->{id}, ERR_PARSE, $text, $self->client);

            } else {

                $kernel->yield('_jsonrpc_error', $request->{id}, ERR_SERVER, "Server error", $self->client);
                
            }

        }

    }

}

sub _client_connection_failed {
    my ($kernel, $self, $syscall, $errnum, $errstr, $wheel_id) = 
      @_[KERNEL,OBJECT,ARG0 .. ARG3];

    $self->log->error($self->message('connection_failed', $errnum, $errstr));
    delete $self->{listener};

}

sub _client_error {
    my ($kernel, $self, $syscall, $errnum, $errstr, $wheel_id) =
      @_[KERNEL,OBJECT,ARG0 .. ARG3];

    $self->log->error($self->message('client_error', $errnum, $errstr));
    delete $self->{client};

}

sub _jsonrpc_error {
    my ($kernel, $self, $id, $code, $message, $wheel) = @_[KERNEL,OBJECT,ARG0 .. ARG4];

    my $packet;
    my $response = {
        jsonrpc => JSONRPC,
        id      => $id,
        error   => {
            code    => $code,
            message => $message
        }
    };

    $packet = encode($response);
    $wheel->put($packet);

}

sub _jsonrpc_result {
    my ($kernel, $self, $id, $result, $wheel) = @_[KERNEL,OBJECT,ARG0,ARG1,ARG2];

    my $packet;
    my $response = {
        jsonrpc => JSONRPC,
        id      => $id,
        result  => $result
    };

    $packet = encode($response);
    $wheel->put($packet);

}

1;

__END__

=head1 NAME

Supervisor::RPC::Server - A RPC interface to the Superviors environment

=head1 SYNOPSIS

 my $supervisor = Supervisor::Controller->new(
     Name => 'supervisor',
     Logfile => '/dev/stdout',
     Processes => Supervisor::ProcessFactory->load(
         Config => 'supervisor.ini',
         Supervisor => 'suprvisor',
     ),
     RPC => Supervisor::RPC::Server->new(
         Name => 'rpc',
         Port => 9505,
         Address => 127.0.0.1,
         Logfile => '/dev/stdout'
         Supervisor => 'supervisor',
     )
 );

 $supervisor->run;

=head1 DESCRIPTION

This module allows the supervisor environment to interface with external agents.
This is done thru a limited RPC interface. The RPC format is based 
on JSON-RPC v2.0.  

=head1 METHODS

=over 4

=item new

This initializes the module and starts listening for requests. There are
five parameters that can be passed. They are the following:

 Name       - the name of the RPC session.
 Port       - the IP port to listen on (default 9505)
 Address    - the address to bind to (default 127.0.0.1)
 Logfile    - the logfile to use
 Supervisor - the name of the Controller session.

=back

=head1 RPC Functions

=over 4

=item stop_process

This method takes the passed process name, creates a data structure and 
triggers the "stop_process" event in the supervisors context. When the 
process is stopped, a message is sent back to the client.

=item start_process

This method takes the passed process name, creates a data structure and 
triggers the "start_process" event in the supervisors context. When the 
process is started, a message is sent back to the client.

=item stat_process

This method takes the passed process name, creates a data structure and 
triggers the "stat_process" event in the supervisors context. The status
of the process is sent back to the client.

=item reload_process

This method takes the passed process name, creates a data structure and 
triggers the "reload_process" event in the supervisors context. When done, 
a message is sent back to the client.

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
