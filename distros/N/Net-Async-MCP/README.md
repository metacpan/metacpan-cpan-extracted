# Net::Async::MCP

Async [MCP (Model Context Protocol)](https://modelcontextprotocol.io) client for IO::Async.

Connect to MCP servers from Perl using async/await. Works with in-process Perl
servers (via [MCP](https://metacpan.org/pod/MCP) module) and external servers
over stdio (Node.js, Python, Go, etc.).

## Synopsis

```perl
use IO::Async::Loop;
use Net::Async::MCP;
use Future::AsyncAwait;

my $loop = IO::Async::Loop->new;

# In-process: direct MCP::Server calls (fastest)
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

# Stdio: spawn external MCP server
my $mcp_stdio = Net::Async::MCP->new(
    command => ['npx', '@anthropic/mcp-server-web-search'],
);
$loop->add($mcp_stdio);

# HTTP: remote MCP server
my $mcp_http = Net::Async::MCP->new(
    url => 'https://example.com/mcp',
);
$loop->add($mcp_http);

# Same API for all transports
async sub main {
    await $mcp->initialize;

    my $tools = await $mcp->list_tools;
    say "Available: ", join(', ', map { $_->{name} } @$tools);

    my $result = await $mcp->call_tool('echo', { message => 'Hello MCP!' });
    say $result->{content}[0]{text};  # "Echo: Hello MCP!"

    await $mcp->shutdown;
}

main()->get;
```

## Transports

| Transport | Constructor | Use case |
|-----------|-------------|----------|
| **InProcess** | `server => $mcp_server` | Perl MCP::Server in same process |
| **Stdio** | `command => [...]` | External servers (any language) |
| **HTTP** | `url => '...'` | Remote servers (Streamable HTTP) |

## Installation

```
cpanm Net::Async::MCP
```

## Dependencies

- [IO::Async](https://metacpan.org/pod/IO::Async) >= 0.78
- [Future::AsyncAwait](https://metacpan.org/pod/Future::AsyncAwait) >= 0.66
- [JSON::MaybeXS](https://metacpan.org/pod/JSON::MaybeXS)
- [MCP](https://metacpan.org/pod/MCP) >= 0.07 (recommended, required for InProcess transport)
- [Net::Async::HTTP](https://metacpan.org/pod/Net::Async::HTTP) (recommended, required for HTTP transport)

## See also

- [MCP](https://metacpan.org/pod/MCP) - Perl MCP server SDK by Sebastian Riedel
- [Langertha](https://metacpan.org/pod/Langertha) - Perl LLM interface (uses Net::Async::MCP for tool calling)
- [MCP Specification](https://modelcontextprotocol.io)
