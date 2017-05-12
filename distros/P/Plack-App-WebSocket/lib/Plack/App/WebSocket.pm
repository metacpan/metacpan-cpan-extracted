package Plack::App::WebSocket;
use strict;
use warnings;
use parent qw(Plack::Component);
use Carp;
use Plack::Response;
use AnyEvent::WebSocket::Server;
use Try::Tiny;
use Plack::App::WebSocket::Connection;
use Scalar::Util qw(blessed);

our $VERSION = "0.05";

my $ERROR_ENV = "plack.app.websocket.error";

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    croak "on_establish param is mandatory" if not defined $self->{on_establish};
    croak "on_establish param must be a code-ref" if ref($self->{on_establish}) ne "CODE";
    $self->{on_error} ||= \&_default_on_error;
    croak "on_error param must be a code-ref" if ref($self->{on_error}) ne "CODE";

    if(!defined($self->{websocket_server})) {
        $self->{websocket_server} = AnyEvent::WebSocket::Server->new();
    }
    if(blessed($self->{websocket_server}) && !$self->{websocket_server}->isa("AnyEvent::WebSocket::Server")) {
        croak "websocket_server param must be a AnyEvent::WebSocket::Server";
    }
    
    return $self;
}

sub _default_on_error {
    my ($env) = @_;
    my $res = Plack::Response->new;
    $res->content_type("text/plain");
    if(!defined($env->{$ERROR_ENV})) {
        $res->status(500);
        $res->body("Unknown error");
    }elsif($env->{$ERROR_ENV} eq "not supported by the PSGI server") {
        $res->status(500);
        $res->body("The server does not support WebSocket.");
    }elsif($env->{$ERROR_ENV} eq "invalid request") {
        $res->status(400);
        $res->body("The request is invalid for a WebSocket request.");
    }else {
        $res->status(500);
        $res->body("Unknown error: $env->{$ERROR_ENV}");
    }
    $res->content_length(length($res->body));
    return $res->finalize;
}

sub _respond_via {
    my ($responder, $psgi_res) = @_;
    if(ref($psgi_res) eq "CODE") {
        $psgi_res->($responder);
    }else {
        $responder->($psgi_res);
    }
}

sub call {
    my ($self, $env) = @_;
    if(!$env->{"psgi.streaming"} || !$env->{"psgi.nonblocking"} || !$env->{"psgix.io"}) {
        $env->{$ERROR_ENV} = "not supported by the PSGI server";
        return $self->{on_error}->($env);
    }
    my $cv_conn = $self->{websocket_server}->establish_psgi($env, $env->{"psgix.io"});
    return sub {
        my $responder = shift;
        $cv_conn->cb(sub {
            my ($cv_conn) = @_;
            my ($conn, $error) = try {
                (scalar($cv_conn->recv), undef);
            }catch {
                (undef, $_[0]);
            };
            if(!$conn) {
                $env->{$ERROR_ENV} = "invalid request";
                $env->{"plack.app.websocket.error.handshake"} = $error;
                _respond_via($responder, $self->{on_error}->($env));
                return;
            }
            $self->{on_establish}->(Plack::App::WebSocket::Connection->new($conn, $responder), $env);
        });
    };
}

1;

__END__

=pod

=head1 NAME

Plack::App::WebSocket - WebSocket server as a PSGI application

=head1 SYNOPSIS

    use Plack::App::WebSocket;
    use Plack::Builder;
    
    builder {
        mount "/websocket" => Plack::App::WebSocket->new(
            on_error => sub {
                my $env = shift;
                return [500,
                        ["Content-Type" => "text/plain"],
                        ["Error: " . $env->{"plack.app.websocket.error"}]];
            },
            on_establish => sub {
                my $conn = shift; ## Plack::App::WebSocket::Connection object
                my $env = shift;  ## PSGI env
                $conn->on(
                    message => sub {
                        my ($conn, $msg) = @_;
                        $conn->send($msg);
                    },
                    finish => sub {
                        undef $conn;
                        warn "Bye!!\n";
                    },
                );
            }
        )->to_app;
        
        mount "/" => $your_app;
    };

=head1 DESCRIPTION

This module is a L<PSGI> application that creates an endpoint for WebSocket connections.

=head2 Prerequisites

To use L<Plack::App::WebSocket>, your L<PSGI> server must meet the following requirements.
(L<Twiggy> meets all of them, for example)

=over

=item *

C<psgi.streaming> environment is true.

=item *

C<psgi.nonblocking> environment is true, and the server supports L<AnyEvent>.

=item *

C<psgix.io> environment holds a valid raw IO socket object. See L<PSGI::Extensions>.

=back

=head1 CLASS METHODS

=head2 $app = Plack::App::WebSocket->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<on_establish> => CODE (mandatory)

A subroutine reference that is called each time it establishes a new
WebSocket connection to a client.

The code is called like

    $code->($connection, $psgi_env)

where C<$connection> is a L<Plack::App::WebSocket::Connection> object
and C<$psgi_env> is the PSGI environment object for the connection request.
You can use the C<$connection> to communicate with the client.

Make sure you keep C<$connection> object as long as you need it.
If you lose reference to C<$connection> object and it's destroyed,
the WebSocket connection (and its underlying transport connection) is closed.

=item C<on_error> => PSGI_APP (optional)

A subroutine reference that is called when some error
happens while processing a request.

The code is a L<PSGI> app, so it's called like

    $psgi_response = $code->($psgi_env)

C<$psgi_response> is returned to the client instead of a valid
WebSocket handshake response.

When C<$code> is called, C<< $psgi_env->{"plack.app.websocket.error"} >> contains a string
that briefly describes the error (See below).

By default, it returns a simple non-200 HTTP response according to C<< $psgi_env->{"plack.app.websocket.error"} >>.
See below for detail.

=item C<websocket_server> => L<AnyEvent::WebSocket::Server> (optional)

The backend L<AnyEvent::WebSocket::Server> instance.
By default, C<< AnyEvent::WebSocket::Server->new() >> is used.

=back

=head1 C<plack.app.websocket.error> ENVIRONMENT STRINGS

Below is the list of possible values of C<plack.app.websocket.error> L<PSGI> environment parameter.
It is set in the C<on_error> callback.

=over

=item C<"not supported by the PSGI server">

The L<PSGI> server does not support L<Plack::App::WebSocket>. See L</Prerequisites>.

By default, 500 "Internal Server Error" response is returned for this error.

=item C<"invalid request">

The client sent an invalid request.
In this case, C<< $psgi_env->{"plack.app.websocket.error.handshake"} >> keeps the exception thrown by the handshake process.

By default, 400 "Bad Request" response is returned for this error.

=back

=head1 OBJECT METHODS

=head2 $psgi_response = $app->call($psgi_env)

Process the L<PSGI> environment (C<$psgi_env>) and returns a L<PSGI> response (C<$psgi_response>).

=head2 $app_code = $app->to_app

Return a L<PSGI> application subroutine reference.

=head1 SEE ALSO

=over

=item L<Amon2::Plugin::Web::WebSocket>

WebSocket implementation for L<Amon2> Web application framework.

=item L<Mojo::Transaction::WebSocket>

WebSocket implementation for L<Mojolicious> Web application framework.

=item L<PocketIO>

Socket.io implementation as a L<PSGI> application.

=item L<SockJS>

SockJS implementation as a L<PSGI> application.

=back

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=head1 CONTRIBUTORS

leedo

=head1 REPOSITORY

L<https://github.com/debug-ito/Plack-App-WebSocket>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
