package POEx::Role::PSGIServer;
$POEx::Role::PSGIServer::VERSION = '1.150280';
#ABSTRACT: (DEPRECATED) Encapsulates core PSGI server behavior
use MooseX::Declare;


role POEx::Role::PSGIServer {
    use aliased 'POEx::Role::Event';

    use MooseX::Types::Moose(':all');
    use POEx::Types::PSGIServer(':all');
    use POEx::Types(':all');
    use Moose::Autobox;
    use HTTP::Message::PSGI;
    use HTTP::Status qw(status_message);
    use Plack::Util;
    use POE::Filter::HTTP::Parser;
    use POE::Filter::Stream;
    use POEx::Role::PSGIServer::Streamer;
    use POEx::Role::PSGIServer::ProxyWriter;


    has psgi_app => (
        is => 'ro',
        isa => CodeRef,
        writer => 'register_service',
    );


    has wheel_flushers => (
        is      => 'ro',
        traits  => ['Hash'],
        isa     => 'HashRef',
        default => sub { {} },
        handles => {
            has_wheel_flusher   => 'exists',
            get_wheel_flusher   => 'get',
            set_wheel_flusher   => 'set',
            clear_wheel_flusher => 'delete',
        }
    );



    around BUILDARGS(ClassName $class: @args) {
        my $hash = $class->$orig(@args);

        $hash->{listen_port} ||= delete $hash->{port} || 5000;
        $hash->{listen_ip}   ||= delete $hash->{host} || '0.0.0.0';
        $hash;
    }


    after _start is Event {
        $self->input_filter(POE::Filter::HTTP::Parser->new(type => 'server'));
        $self->output_filter(POE::Filter::Stream->new());
    }


    method write(PSGIServerContext $c, Str $data) {
        if($c->{chunked}) {
            my $len = sprintf "%X", do { use bytes; length($data) };
            $self->_write($c, "$len\r\n$data\r\n");
        }
        else {
            $self->_write($c, $data);
        }
        
    }


    method _write(PSGIServerContext $c, Str $data) {
        $c->{wheel}->put($data);
    }


    method close(PSGIServerContext $c) {
        if($c->{chunked}) {
            $self->_write($c, "0\r\n\r\n");
        }

        $c->{wheel}->flush() while $c->{wheel}->get_driver_out_octets();
        $c->{wheel}->shutdown_output();
        $self->delete_wheel((delete $c->{wheel})->ID);
    }


    method handle_socket_error(Str $action, Int $code, Str $message, WheelID $id) is Event {
        $self->delete_wheel($id);
    }


    method handle_listen_error(Str $action, Int $code, Str $message, WheelID $id) is Event {
        die "Failed to '$action' to the specified port. Code: $code, Message: $message";
    }



    method process_headers(PSGIServerContext $c, PSGIResponse $response) {
        my $headers = $response->[1];
        $headers->keys
            ->each(
                sub {
                    my $index = shift;
                    return if $index == $#$headers;
                    my ($k, $v) = ($headers->[$index], $headers->[$index+1]) ;
                    $c->{keep_alive} = 0 if $k eq 'Connection' && $v eq 'close';
                    $c->{explicit_length} = 1 if $k eq 'Content-Length';
                    $self->_write($c, "$k:$v\r\n");
                }
            );
        
        $c->{chunked} = ($c->{keep_alive} && !$c->{explicit_length});
    }


    method http_preamble(PSGIServerContext $c, PSGIResponse $response) {
        $self->_write($c, "${\ $c->{protocol}} ${\ $response->[0] } ${ \status_message($response->[0]) }\r\n");
    }


    method http_body_allowed(PSGIServerContext $c, PSGIResponse $response) returns (Bool) {
        my $code = $response->[0];

        my $no_body_allowed = ($c->{request}->method =~ /^head$/i)
           || ($code < 200)
           || ($code == 204)
           || ($code == 304);

        if ($no_body_allowed) {
            $self->_write($c, "\r\n");
            $self->close($c);
            return Plack::Util::FALSE;
        }

        return Plack::Util::TRUE;
    }


    method respond(PSGIServerContext $c, PSGIResponse $response) is Event {
        $self->http_preamble($c, $response);
        $self->process_headers($c, $response);
        return unless ($self->http_body_allowed($c, $response));

       
        $self->_write($c, "Transfer-Encoding: chunked\r\n") if $c->{chunked};
        $self->_write($c, "\r\n");
        
        my $body = $response->[2];
        if ($body) {
            # If we have a real filehandle, build a Streamer
            if (Plack::Util::is_real_fh($body)) {
                # flush and destroy the old wheel, since the Streamer will build a new one
                $c->{wheel}->flush();
                $self->delete_wheel($c->{wheel}->ID);
                my $handle = (delete $c->{wheel})->get_input_handle();
                my $streamer = POEx::Role::PSGIServer::Streamer->new(
                    input_handle => $body,
                    output_handle => $handle,
                    server_context => $c,
                );
            }
            # If we don't just iterate the lines
            else {
                Plack::Util::foreach($body, sub{$self->write($c, @_)});
                $self->close($c);
            }

            return;
        }

        # If there was no body, we need to build a push writer
        return $self->generate_push_writer($c);
    }


    method generate_push_writer(PSGIServerContext $c) returns (Object) {
        return POEx::Role::PSGIServer::ProxyWriter->new(server_context => $c, proxied => $self);
    }


    method generate_psgi_env(PSGIServerContext $c) returns (HashRef) {
        return req_to_psgi(
            $c->{request},
            SERVER_NAME         => $self->listen_ip,
            SERVER_PORT         => $self->listen_port,
            SERVER_PROTOCOL     => $c->{protocol},
            'psgi.streaming'    => Plack::Util::TRUE,
            'psgi.nonblocking'  => Plack::Util::TRUE,
            'psgi.runonce'      => Plack::Util::FALSE,
        );
    }


    method build_server_context(HTTPRequest $req, WheelID $wheel_id) returns (PSGIServerContext) {
        my $version  = $req->header('X-HTTP-Version') || '0.9';
        my $protocol = "HTTP/$version";
        my $connection = $req->header('Connection') || '';
        my $keep_alive = ($version eq '1.1' && $connection ne 'close');
        
        my $context = {
            request => $req,
            wheel => $self->get_wheel($wheel_id),
            version => $version,
            protocol => $protocol,
            connection => $connection,
            keep_alive => $keep_alive,
            explicit_length => 0,
        };

        return $context;
    }


    method handle_inbound_data(HTTPRequest $req, WheelID $wheel_id) is Event {
        my $context = $self->build_server_context($req, $wheel_id);
        my $env = $self->generate_psgi_env($context);
        my $response = Plack::Util::run_app($self->psgi_app, $env);

        if (ref($response) eq 'CODE') {
            $response->(sub { $self->respond($context, @_) });
        }
        else {
            $self->yield('respond', $context, $response);
        }
    }


    method run(CodeRef $app) {
        $self->register_service($app);
        POE::Kernel->run();
    }

    method handle_on_flushed(WheelID $id) is Event {
        if ($self->has_wheel_flusher($id)) {
            $self->get_wheel_flusher($id)->();
        }
        1;
    }

    after delete_wheel(WheelID $id) {
        $self->clear_wheel_flusher($id);
    }

    with 'POEx::Role::TCPServer' => {
        -excludes => [
            qw/handle_socket_error handle_listen_error handle_on_flushed/
        ]
    };
}

__END__

=pod

=head1 NAME

POEx::Role::PSGIServer - (DEPRECATED) Encapsulates core PSGI server behavior

=head1 VERSION

version 1.150280

=head1 SYNOPSIS

    use MooseX::Declare;
    class MyServer with POEx::Role::PSGIServer { }

    MyServer->new()->run($some_psgi_app);

=head1 DESCRIPTION

This module has been deprecated.

POEx::Role::PSGIServer encapsulates the core L<PSGI> server behaviors into an easy to consume and extend role. It is based on previous POEx work such as POEx::Role::TCPServer which provides basic TCP socket multiplexing via POE::Wheel::SocketFactory and POE::Wheel::ReadWrite, and POEx::Role::SessionInstantiation which transforms plain Moose objects into POE sessions.

=head2 RATIONALE

This Role has its roots firmly planted in POE::Component::Server::PSGI which provided the initial seed with the layout and logic of the basic server. Unfortunately, POE::Component::Server::PSGI didn't provide any mechnism for extension. The main goal of this Role is to provide as many extension points as possible. The secondary goal is to provide a more reasonable abstraction for several key pieces of the stack for streaming, and push writing.

=head1 CLASS_METHODS

=head2 around BUILDARGS

    (ClassName $class: @args)

BUILDARGS is wrapped to translate from the expected Plack::Handler interface to POEx::Role::TCPServer's expected interface.

=head1 PUBLIC_ATTRIBUTES

=head2 psgi_app

    is: ro, isa: CodeRef, writer: register_service

This attribute stores the PSGI application to be run from this server. A writer method is provided to match the expected Plack::Handler interface

=head1 PROTECTED_ATTRIBUTES

=head2 wheel_flushers

    is: ro, isa: HashRef,
    exists : has_wheel_flusher,
    get    : get_wheel_flusher,
    set    : set_wheel_flusher,
    delete : clear_wheel_flusher

This attribute stores coderefs to be called on a wheel's flush event
(necessary to properly handle poll_cb)

=head1 PUBLIC_METHODS

=head2 run

    (CodeRef $app)

run is provided to complete the Plack::Handler interface and allow the server to be executed with the provided psgi app

=head1 PROTECTED_METHODS

=head2 after _start

    is Event

_start is advised to supply the proper input (HTTP::Parser) and output (Stream) filters.

=head2 write

    (PSGIServerContext $c, Str $data)

write will alter the data if necessary for a chunked transfer encoded response and send it to the output buffer for the current context

=head2 close

    (PSGIServerContext $c)

close will close the connection for the current context, but flushing the output buffer first

=head2 handle_socket_error

    (Str $action, Int $code, Str $message, WheelID $id) is Event

handle_socket_error overridden from POEx::Role::TCPServer to delete the wheel when a socket level error happens. If more intelligent actions are required, please feel free to exclude this method and provide your own implementation

=head2 handle_listen_error

    (Str $action, Int $code, Str $message, WheelID $id) is Event

handle_listen_error is overridden from POEx::Role::TCPServer to die when the SocketFactory fails to listen to the provided address/port. If more intelligent actions are required, please feel free to exclude this method and provide your own implementation

=head2 process_headers

    (PSGIServerContext $c, PSGIResponse $response)

process_headers takes the headers from the PSGIResponse, and sends it to the output buffer for the current context. This method also determines if the response body should be transfer encoded as chunked based on the Connection and Content-Length headers.

=head2 http_preamble

    (PSGIServerContext $c, PSGIResponse $response)

http_preamble sends the first line of the HTTP response to the output buffer of the current context

=head2 http_body_allowed

    (PSGIServerContext $c, PSGIResponse $response) returns (Bool)

http_body_allowed checks the result code from the PSGIResponse to determine if a body should be allowed to be returned. Returns true if a body is allowed, false otherwise.

=head2 respond

    (PSGIServerContext $c, PSGIResponse $response) is Event

respond processes the PSGIResponse to write out a valid HTTP response. If the body of the response is a real filehandle, it will be streamed appropriately via L<POEx::Role::PSGIServer::Streamer>. If not, it will be iterated with which ever appropriate interface to the output buffer. If no body is provided, L</generate_push_writer> is called to generate an appropriate object for use in push responses.

=head2 generate_push_writer

    (PSGIServerContext $c) returns (Object)

generate_push_writer by default constructs and returns a L<POEx::Role::PSGIServer::ProxyWriter> object that implements the push-object interface defined in L<PSGI>

=head2 generate_psgi_env

    (PSGIServerContext $c) returns (HashRef)

generate_psgi_env returns a suitable HashRef as defined by L<PSGI> for application use. If additional application specific items need to be added to the hash, please feel free to advise this method

=head2 build_server_context

    (HTTPRequest $req, WheelID $wheel_id) returns (PSGIServerContext)

build_server_context constructs and returns a L<POEx::Types::PSGIServer/PSGIServerContext> for the current connection

=head2 handle_inbound_data

    (HTTPRequest $req, WheelID $wheel_id) is Event

handle_inbound_data implements the required method for POEx::Role::TCPServer. It builds a server context, generates a psgi env hash, runs the psgi app, and then responds to the client

=head1 PRIVATE_METHODS

=head2 _write

    (PSGIServerContext $c, Str $data)

_write accesses the proper wheel for this context and puts the supplied data into the output buffer

=head1 AUTHOR

Nicholas Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
