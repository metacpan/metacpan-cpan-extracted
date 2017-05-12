package POE::Component::Server::JSONRPC;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

our $VERSION = '0.05';

use POE qw/
    Filter::Line
    /;
use JSON;

=head1 NAME

POE::Component::Server::JSONRPC - POE tcp or http based JSON-RPC server

=head1 SYNOPSIS

    #http version:
    POE::Component::Server::JSONRPC::Http->new(
        Port    => 3000,
        Handler => {
            'echo' => 'echo',
            'sum'  => 'sum',
        },
        SslKey  => '/path/to/the/server.key',
        SslCert => '/path/to/the/server.crt',
        Authenticate => \&authentication_handler,
        # authentication_handler must be a function that takes two parameters login and password,
        # and returns true if connection is successful, false otherwise
    );

    #tcp version:
    POE::Component::Server::JSONRPC::Tcp->new(
        Port    => 3000,
        Handler => {
            'echo' => 'echo',
            'sum'  => 'sum',
        },
    );

    sub echo {
        my ($kernel, $jsonrpc, $id, @params) = @_[KERNEL, ARG0..$#_ ];

        $kernel->post( $jsonrpc => 'result' => $id, @params );
    }

    sub sum {
        my ($kernel, $jsonrpc, $id, @params) = @_[KERNEL, ARG0..$#_ ];

        $kernel->post( $jsonrpc => 'result' => $id, $params[0] + $params[1] );
    }

=head1 DESCRIPTION

This module is a POE component for tcp or http based JSON-RPC Server.

The specification is defined on http://json-rpc.org/ and this module use JSON-RPC 1.0 spec (1.1 does not cover tcp streams)

=head1 METHODS

=head2 new

Create JSONRPC component session and return the session id.

Parameters:

=over

=item Port

Port number for listen.

=item Handler

Hash variable contains handler name as key, handler poe state name as value.

Handler name (key) is used as JSON-RPC method name.

So if you send {"method":"echo"}, this module call the poe state named "echo".

=back

=cut

sub new {
    my $self = shift->SUPER::new( @_ > 1 ? {@_} : $_[0] );

    $self->{parent} = $poe_kernel->get_active_session->ID;
    $self->{json} ||= JSON->new;

    my $session = POE::Session->create(
        object_states => [
            $self => {
                map { ( $_ => "poe_$_", ) }
                    qw/_start init_server input_handler result error send/
            },
        ],
    );

    $session->ID;
}

=head1 HANDLER PARAMETERS

=over

=item ARG0

A session id of PoCo::Server::JSONRPC itself.

=item ARG1

The id of the client you're treating, send that back in result/error.

=item ARG2 .. ARGN

JSONRPC argguments

=back

ex) If you send following request

    {"method":"echo", "params":["foo", "bar"]}

then, "echo" handler is called and parameters is that ARG0 is component session id, ARG1 is client id, ARG2 "foo", ARG3 "bar".

=head1 HANDLER RESPONSE

You must call either "result" or "error" state in your handlers to response result or error.

ex:

   $kernel->post( $component_session_id => "result" => $client_id, "result value" )

$component_session_id is ARG0 in handler. If you do above, response is:

   {"result":"result value", "error":""}


=head1 POE METHODS

Inner method for POE states.

=head2 poe__start

=cut

sub poe__start {
    my ($self, $kernel, $session, $heap) = @_[OBJECT, KERNEL, SESSION, HEAP];

    $heap->{clients} = {};
    $heap->{id} = 0;

    $kernel->yield('init_server');
}

=head2 poe_init_server

Should be defined in Http or Tcp
=cut

sub poe_init_server { print "error init_server\n"; }

=head2 poe_input_handler

=cut

sub poe_input_handler {
    my ($self, $kernel, $session, $heap, $request, $response, $dirmatch) = @_[OBJECT, KERNEL, SESSION, HEAP, ARG0..$#_ ];

    $heap->{clients}->{$heap->{id}} = {json_id => undef, response => $response};

    my $json;
    eval {
        $json = $self->{json}->decode( $request->content );
    };
    if ($@) {
        $kernel->yield('error', $heap->{id}, q{invalid json request});
        return;
    }

    $heap->{clients}->{$heap->{id}} = {json_id => $json->{id}, response => $response};

    unless ($json and $json->{method}) {
        $kernel->yield('error', $heap->{id}, q{parameter "method" is required});
        return;
    }

    unless ($self->{Handler}{ $json->{method} }) {
        $kernel->yield('error', $heap->{id}, qq{no such method "$json->{method}"});
        return;
    }

    my $handler = $self->{Handler}{ $json->{method} };
    my @params = @{ $json->{params} || [] };

    $kernel->post($self->{parent}, $handler, $session->ID, $heap->{id}, @params);

    $heap->{id}++;
    if ($heap->{id}>=65535) { # limit to 2 bytes
        $heap->{id} = 0;
    }
}

=head2 poe_result

=cut

sub poe_result {
    my ($self, $kernel, $heap, $id, @results) = @_[OBJECT, KERNEL, HEAP, ARG0..$#_ ];

    #~ print "answering to ".$id."\n";

    my $client = $heap->{clients}->{$id};

    my $json_content = $self->{json}->encode(
            {   id => $client->{json_id} || undef,
                error  => undef,
                result => (@results > 1 ? \@results : $results[0]),
            }
        );

    #~ print "json content : ".$json_content."\n";

    $kernel->yield('send',$client->{response},$json_content);
    delete $heap->{clients}->{$id};
}

=head2 poe_error

=cut

sub poe_error {
    my ($self, $kernel, $heap, $id, $error) = @_[OBJECT, KERNEL, HEAP, ARG0..$#_];

    my $client = $heap->{clients}->{$id};

    my $json_error_content = $self->{json}->encode(
        {   id => $client->{json_id} || undef,
            error  => $error,
            result => undef,
        }
    );

    #~ print "json content : ".$json_error_content."\n";

    $kernel->yield('send',$client->{response},$json_error_content);
    delete $heap->{clients}->{$id};
}

=head2 poe_send

Should be defined in Http or Tcp
=cut

sub poe_send { print "error poe_send\n"; }

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>
Côme BERNIGAUD <come.bernigaud@laposte.net>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
