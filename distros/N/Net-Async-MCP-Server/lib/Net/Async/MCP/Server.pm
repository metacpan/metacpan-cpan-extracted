package Net::Async::MCP::Server;
# ABSTRACT: Async MCP server base class

use strict;
use warnings;

use parent 'IO::Async::Notifier';

use Future::AsyncAwait;

our $VERSION = '0.001';


sub _init {
  my ( $self, $params ) = @_;
  $self->SUPER::_init($params);
}

sub configure {
  my ( $self, %params ) = @_;
  if (exists $params{name}) {
    $self->{name} = delete $params{name};
  }
}

sub _add_to_loop {
  my ( $self, $loop ) = @_;
  $self->SUPER::_add_to_loop($loop);
}

sub name { shift->{name} // 'NetAsyncMCPServer' }


sub server_info {
    my ( $self ) = @_;
    return {
        name    => $self->name,
        version => $VERSION,
    };
}


sub server_capabilities {
    my ( $self ) = @_;
    return $self->{server_capabilities} // {};
}


async sub initialize {
    my ( $self ) = @_;

    $self->{server_capabilities} = $self->_build_capabilities;
    $self->{_initialized} = 1;

    return {
        protocolVersion => '2025-11-25',
        capabilities    => $self->server_capabilities,
        serverInfo      => $self->server_info,
    };
}


sub _build_capabilities {
    my ( $self ) = @_;
    return { tools => {} };
}

sub tools {
    my ( $self ) = @_;
    return $self->{tools} // [];
}


sub register_tool {
    my ( $self, %tool ) = @_;
    $self->{tools} //= [];
    push @{ $self->{tools} }, \%tool;
}


async sub list_tools {
    my ( $self ) = @_;
    return $self->tools;
}


async sub call_tool {
    my ( $self, $name, $arguments ) = @_;

    my $tool = $self->_find_tool($name);
    die "No tool registered: $name" unless $tool;

    if (my $code = $tool->{code}) {
        return $code->($arguments);
    }

    die "Tool '$name' has no implementation";
}

sub _find_tool {
    my ( $self, $name ) = @_;
    for my $tool (@{ $self->{tools} // [] }) {
        return $tool if $tool->{name} eq $name;
    }
    return undef;
}


sub handle {
    my ( $self, $request, $context ) = @_;

    return _jsonrpc_error( -32700, 'Invalid JSON-RPC request' )
        unless ref $request eq 'HASH';

    my $method = $request->{method};
    my $id     = $request->{id};

    return _jsonrpc_error( -32600, 'Missing JSON-RPC method', $id )
        unless defined $method;

    if ( defined $id ) {
        if ( $method eq 'initialize' ) {
            return $self->_handle_initialize( $request->{params} // {}, $id );
        }
        elsif ( $method eq 'tools/list' ) {
            return $self->_handle_tools_list( $id );
        }
        elsif ( $method eq 'tools/call' ) {
            return $self->_handle_tools_call( $request->{params} // {}, $id );
        }
        elsif ( $method eq 'ping' ) {
            return _jsonrpc_response( {}, $id );
        }

        return _jsonrpc_error( -32601, "Method '$method' not found", $id );
    }

    if ( $method eq 'notifications/initialized' ) {
        return undef;
    }
    elsif ( $method eq 'shutdown' ) {
        return undef;
    }

    return undef;
}

sub _handle_initialize {
    my ( $self, $params, $id ) = @_;

    my $result = $self->initialize->get;

    return _jsonrpc_response( $result, $id );
}

sub _handle_tools_list {
    my ( $self, $id ) = @_;

    my $tools = $self->list_tools->get;
    return _jsonrpc_response( { tools => $tools }, $id );
}

sub _handle_tools_call {
    my ( $self, $params, $id ) = @_;

    my $name = $params->{name}      // '';
    my $args = $params->{arguments} // {};

    my $result = $self->call_tool( $name, $args )->get;
    return _jsonrpc_response( $result, $id );
}

sub _jsonrpc_error {
    my ( $code, $message, $id ) = @_;
    return {
        jsonrpc => '2.0',
        id      => $id,
        error   => { code => $code, message => $message },
    };
}

sub _jsonrpc_response {
    my ( $result, $id ) = @_;
    return { jsonrpc => '2.0', id => $id, result => $result };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP::Server - Async MCP server base class

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::MCP::Server;
    use Net::Async::MCP::Server::Transport::Stdio;

    my $loop = IO::Async::Loop->new;

    my $server = Net::Async::MCP::Server->new(
        name => 'my-server',
    );

    $loop->add($server);

    Net::Async::MCP::Server::Transport::Stdio->new(
        server => $server,
    )->handle_requests;

=head1 DESCRIPTION

L<Net::Async::MCP::Server> is an asynchronous MCP (Model Context Protocol) server
built on L<IO::Async>. It handles the MCP protocol handshake and request routing,
allowing subclasses to implement specific tools.

=head2 name

Returns the server name exposed via MCP protocol.

=head2 server_info

Returns a hashref with C<name> and C<version> keys for the MCP protocol.

=head2 server_capabilities

Returns the server capabilities hashref.

=head2 initialize

Performs MCP server initialization. Handles the C<initialize> request from the
client, returns server info and capabilities.

=head2 tools

Returns ArrayRef of registered tool definitions.

=head2 register_tool(%tool)

Registers a tool. Expects C<name>, C<description>, C<input_schema>, C<code>.

=head2 list_tools

Returns ArrayRef of tool definitions.

=head2 call_tool($name, $arguments)

Called when a client invokes a tool. Subclasses should override to provide
tool implementations.

=head1 SEE ALSO

L<Net::Async::MCP::Server::Transport::Stdio>, L<IO::Async::Notifier>, L<Future::AsyncAwait>.

=cut

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
