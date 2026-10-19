requires 'IO::Async', '>= 0.78';
requires 'Future', '>= 0.49';
requires 'Future::AsyncAwait', '>= 0.66';
requires 'JSON::MaybeXS';

recommends 'MCP', '>= 0.15';
recommends 'Net::Async::HTTP';
recommends 'HTTP::Message';

on test => sub {
  requires 'Test2::V0';
  # the tests spell JSON booleans as JSON::MaybeXS::true/false, which are 1.004+
  requires 'JSON::MaybeXS', '>= 1.004';
  requires 'MCP', '>= 0.15';
  # t/bin/test_mcp_server.pl is a Mojo::Base -signatures script; 9.41 is what
  # MCP 0.15 itself requires
  requires 'Mojolicious', '>= 9.41';
};
