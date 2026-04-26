package Net::Async::MCP::Server::Transport::Stdio;
# ABSTRACT: Stdio transport for Net::Async::MCP::Server

use strict;
use warnings;

use parent 'IO::Async::Notifier';

use Future::AsyncAwait;
use JSON::MaybeXS qw( encode_json decode_json );

our $VERSION = '0.001';


sub new {
    my ( $class, %params ) = @_;
    my $server = delete $params{server};
    my $self = $class->SUPER::new(%params);
    $self->{server} = $server if defined $server;
    return $self;
}

sub configure {
    my ( $self, %params ) = @_;
    if ( exists $params{server} ) {
        $self->{server} = delete $params{server};
    }
    $self->SUPER::configure(%params);
}


sub server {
    my ( $self ) = @_;
    return $self->{server};
}


sub handle_requests {
    my ( $self ) = @_;

    my $loop = $self->loop // IO::Async::Loop->new;

    while ( my $line = <STDIN> ) {
        chomp $line;
        next unless length $line;

        my $request = eval { decode_json($line) };
        if ($@) {
            $self->_send_response({
                jsonrpc => '2.0',
                id      => undef,
                error   => { code => -32700, message => 'Parse error' },
            });
            next;
        }

        my $response = $self->server->handle($request);
        if ($response) {
            $self->_send_response($response);
        }
    }
}

sub _send_response {
    my ( $self, $response ) = @_;
    print STDOUT encode_json($response) . "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP::Server::Transport::Stdio - Stdio transport for Net::Async::MCP::Server

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Net::Async::MCP::Server::Transport::Stdio;

    my $transport = Net::Async::MCP::Server::Transport::Stdio->new(
        server => $server,
    );
    $transport->handle_requests;

=head1 DESCRIPTION

Stdio transport for MCP server using newline-delimited JSON-RPC over stdin/stdout.

Each line is a JSON-RPC 2.0 message. Requests are read from stdin, responses written
to stdout.

This transport is suitable for MCP clients that communicate via standard input/output,
such as command-line AI tools.

=head1 PROTOCOL

Each JSON-RPC message is a single line terminated by a newline character.
Request format:

    {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}}

Response format:

    {"jsonrpc": "2.0", "id": 1, "result": {...}}

Error format:

    {"jsonrpc": "2.0", "id": 1, "error": {"code": -32600, "message": "Invalid Request"}}

=head2 server

    my $server = $transport->server;

Returns the associated MCP server instance.

=head2 handle_requests

    $transport->handle_requests;

Enters the main loop, reading JSON-RPC requests from stdin and writing responses
to stdout. This method blocks until stdin is closed or an error occurs.

=head1 SEE ALSO

L<Net::Async::MCP::Server>, L<IO::Async::Notifier>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-mcp-server/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
