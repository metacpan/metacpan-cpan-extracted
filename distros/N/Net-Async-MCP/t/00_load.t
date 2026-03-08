use strict;
use warnings;
use Test2::V0;

ok(eval { require Net::Async::MCP; 1 }, 'Net::Async::MCP loads')
  or diag $@;
ok(eval { require Net::Async::MCP::Transport::InProcess; 1 }, 'Transport::InProcess loads')
  or diag $@;
ok(eval { require Net::Async::MCP::Transport::Stdio; 1 }, 'Transport::Stdio loads')
  or diag $@;
ok(eval { require Net::Async::MCP::Transport::HTTP; 1 }, 'Transport::HTTP loads')
  or diag $@;

done_testing;
