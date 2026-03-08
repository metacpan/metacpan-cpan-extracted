package Net::Async::MCP;
# ABSTRACT: Async MCP (Model Context Protocol) client for IO::Async

use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Future::AsyncAwait;
use Carp qw( croak );

our $VERSION = '0.002';


sub _init {
  my ( $self, $params ) = @_;
  for my $key (qw( server command url )) {
    $self->{$key} = delete $params->{$key} if exists $params->{$key};
  }
  $self->{_initialized} = 0;
  $self->SUPER::_init($params);
}

sub configure {
  my ( $self, %params ) = @_;
  for my $key (qw( server command url )) {
    $self->{$key} = delete $params{$key} if exists $params{$key};
  }
  $self->SUPER::configure(%params);
}

sub _add_to_loop {
  my ( $self, $loop ) = @_;
  $self->SUPER::_add_to_loop($loop);
  $self->_ensure_transport;
}

sub _ensure_transport {
  my ( $self ) = @_;
  return if $self->{transport};

  if ($self->{server}) {
    require Net::Async::MCP::Transport::InProcess;
    $self->{transport} = Net::Async::MCP::Transport::InProcess->new(
      server => $self->{server},
    );
  }
  elsif ($self->{command}) {
    croak "Stdio transport requires being added to an IO::Async::Loop"
      unless $self->loop;
    require Net::Async::MCP::Transport::Stdio;
    my $transport = Net::Async::MCP::Transport::Stdio->new(
      command => $self->{command},
    );
    $self->{transport} = $transport;
    $self->add_child($transport);
  }
  elsif ($self->{url}) {
    croak "HTTP transport requires being added to an IO::Async::Loop"
      unless $self->loop;
    require Net::Async::MCP::Transport::HTTP;
    my $transport = Net::Async::MCP::Transport::HTTP->new(
      url => $self->{url},
    );
    $self->{transport} = $transport;
    $self->add_child($transport);
  }
  else {
    croak "Must provide server, command, or url";
  }
}

sub server_info { $_[0]->{server_info} }


sub server_capabilities { $_[0]->{server_capabilities} }


async sub initialize {
  my ( $self ) = @_;
  $self->_ensure_transport;

  my $result = await $self->{transport}->send_request('initialize', {
    protocolVersion => '2025-11-25',
    capabilities => {},
    clientInfo => {
      name    => 'Net::Async::MCP',
      version => $VERSION,
    },
  });

  $self->{server_info} = $result->{serverInfo};
  $self->{server_capabilities} = $result->{capabilities};
  $self->{_initialized} = 1;

  await $self->{transport}->send_notification('notifications/initialized');

  return $result;
}


async sub list_tools {
  my ( $self ) = @_;
  my $result = await $self->{transport}->send_request('tools/list');
  return $result->{tools} // [];
}


async sub call_tool {
  my ( $self, $name, $arguments ) = @_;
  my $result = await $self->{transport}->send_request('tools/call', {
    name      => $name,
    arguments => $arguments // {},
  });
  return $result;
}


async sub list_prompts {
  my ( $self ) = @_;
  my $result = await $self->{transport}->send_request('prompts/list');
  return $result->{prompts} // [];
}


async sub get_prompt {
  my ( $self, $name, $arguments ) = @_;
  my $result = await $self->{transport}->send_request('prompts/get', {
    name      => $name,
    arguments => $arguments // {},
  });
  return $result;
}


async sub list_resources {
  my ( $self ) = @_;
  my $result = await $self->{transport}->send_request('resources/list');
  return $result->{resources} // [];
}


async sub read_resource {
  my ( $self, $uri ) = @_;
  my $result = await $self->{transport}->send_request('resources/read', {
    uri => $uri,
  });
  return $result;
}


async sub ping {
  my ( $self ) = @_;
  await $self->{transport}->send_request('ping');
  return 1;
}


async sub shutdown {
  my ( $self ) = @_;
  if ($self->{transport} && $self->{transport}->can('close')) {
    await $self->{transport}->close;
  }
  return 1;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP - Async MCP (Model Context Protocol) client for IO::Async

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::MCP;
    use Future::AsyncAwait;

    my $loop = IO::Async::Loop->new;

    # In-process transport (Perl MCP::Server in same process)
    use MCP::Server;
    my $server = MCP::Server->new(name => 'MyServer');
    $server->tool(
        name         => 'echo',
        description  => 'Echo text',
        input_schema => {
            type       => 'object',
            properties => { message => { type => 'string' } },
            required   => ['message'],
        },
        code => sub { return "Echo: $_[1]->{message}" },
    );

    my $mcp = Net::Async::MCP->new(server => $server);
    $loop->add($mcp);

    # Stdio transport (external MCP server subprocess)
    my $mcp_stdio = Net::Async::MCP->new(
        command => ['npx', '@anthropic/mcp-server-web-search'],
    );
    $loop->add($mcp_stdio);

    # HTTP transport (remote MCP server)
    my $mcp_http = Net::Async::MCP->new(
        url => 'https://example.com/mcp',
    );
    $loop->add($mcp_http);

    # All transports share the same async API:
    async sub main {
        await $mcp->initialize;

        my $tools = await $mcp->list_tools;
        # [{name => 'echo', description => '...', inputSchema => {...}}]

        my $result = await $mcp->call_tool('echo', { message => 'Hello' });
        # {content => [{type => 'text', text => 'Echo: Hello'}], isError => \0}

        await $mcp->shutdown;
    }

    main()->get;

=head1 DESCRIPTION

L<Net::Async::MCP> is an asynchronous client for the MCP (Model Context
Protocol) built on L<IO::Async>. It connects to MCP servers via pluggable
transports:

=over 4

=item * B<InProcess> - Direct calls to an L<MCP::Server> instance in the same
process. See L<Net::Async::MCP::Transport::InProcess>.

=item * B<Stdio> - Subprocess communication over stdin/stdout using
newline-delimited JSON-RPC. Works with any MCP server implementation (Perl,
Node.js, Python, etc.). See L<Net::Async::MCP::Transport::Stdio>.

=item * B<HTTP> - Streamable HTTP transport for remote MCP servers. Supports
both JSON and SSE responses, with automatic session management. See
L<Net::Async::MCP::Transport::HTTP>.

=back

All methods return L<Future> objects and work with L<Future::AsyncAwait>.
Call L</initialize> first before using any other MCP methods.

=head2 server_info

    my $info = $mcp->server_info;

Returns the server info hashref from the MCP initialize response. Contains at
minimum C<name> and C<version> keys. Only available after L</initialize> has
been called.

=head2 server_capabilities

    my $caps = $mcp->server_capabilities;

Returns the server capabilities hashref from the MCP initialize response.
Only available after L</initialize> has been called.

=head2 initialize

    my $result = await $mcp->initialize;

Performs the MCP initialization handshake. Must be called before any other MCP
method. Sends protocol version and client info, then receives server info and
capabilities.

Returns a hashref with C<serverInfo> and C<capabilities> keys. Also populates
the L</server_info> and L</server_capabilities> accessors.

=head2 list_tools

    my $tools = await $mcp->list_tools;

Returns an ArrayRef of tool definition hashrefs from the MCP server. Each
hashref contains C<name>, C<description>, and C<inputSchema> keys.

=head2 call_tool

    my $result = await $mcp->call_tool($name, \%arguments);

Calls a named tool on the MCP server with the given arguments hashref.
Returns a hashref with C<content> (ArrayRef of content blocks) and C<isError>
(boolean).

=head2 list_prompts

    my $prompts = await $mcp->list_prompts;

Returns an ArrayRef of prompt definition hashrefs from the MCP server.

=head2 get_prompt

    my $result = await $mcp->get_prompt($name, \%arguments);

Retrieves a named prompt from the MCP server, optionally passing arguments.
Returns the prompt result hashref.

=head2 list_resources

    my $resources = await $mcp->list_resources;

Returns an ArrayRef of resource definition hashrefs from the MCP server.

=head2 read_resource

    my $result = await $mcp->read_resource($uri);

Reads a resource by URI from the MCP server. Returns the resource content
hashref.

=head2 ping

    await $mcp->ping;

Sends a ping request to verify the server is alive and responsive. Returns
C<1> on success, fails the returned L<Future> if the server does not respond.

=head2 shutdown

    await $mcp->shutdown;

Cleanly shuts down the MCP connection. For the Stdio transport this sends
SIGTERM to the subprocess and waits for it to exit. For the InProcess
transport this is a no-op.

=head1 SEE ALSO

=over 4

=item * L<Net::Async::MCP::Transport::InProcess> - In-process transport for Perl MCP servers

=item * L<Net::Async::MCP::Transport::Stdio> - Subprocess transport via stdin/stdout

=item * L<Net::Async::MCP::Transport::HTTP> - Streamable HTTP transport for remote servers

=item * L<IO::Async::Notifier> - Base class

=item * L<Future::AsyncAwait> - Async/await syntax used with this module

=item * L<https://modelcontextprotocol.io> - MCP specification

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-mcp/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
