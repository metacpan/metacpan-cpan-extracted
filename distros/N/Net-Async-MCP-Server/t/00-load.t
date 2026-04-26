use strict;
use warnings;

use Test2::V0;

ok(eval { require Net::Async::MCP::Server; 1 }, 'Net::Async::MCP::Server loads')
    or diag("Error: $@");
ok(eval { require Net::Async::MCP::Server::Transport::Stdio; 1 }, 'Net::Async::MCP::Server::Transport::Stdio loads')
    or diag("Error: $@");

done_testing;
