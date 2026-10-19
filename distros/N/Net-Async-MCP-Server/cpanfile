requires 'IO::Async', '>= 0.78';
requires 'Future', '>= 0.49';
requires 'Future::AsyncAwait', '>= 0.66';
# JSON::MaybeXS::true/false, which the results are built with, are 1.004+
requires 'JSON::MaybeXS', '>= 1.004';

# Streamable HTTP transport
requires 'Plack', '>= 1.0';
requires 'HTTP::Server::PSGI';

on test => sub {
  requires 'Test2::V0';
  requires 'Plack::Test';
  requires 'HTTP::Request::Common';
};

on develop => sub {
  requires 'Dist::Zilla';
};