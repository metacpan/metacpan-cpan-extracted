use strict;
use warnings;
use Test2::V0;

# Public entry points that must always load
my @core_modules = qw(
    PAGI::Tools
    PAGI::Middleware
    PAGI::Middleware::Builder
    PAGI::App::Router
    PAGI::App::File
    PAGI::App::WrapPSGI
    PAGI::Endpoint::HTTP
    PAGI::Endpoint::Router
    PAGI::Endpoint::SSE
    PAGI::Endpoint::WebSocket
    PAGI::Request
    PAGI::Request::Upload
    PAGI::Request::Negotiate
    PAGI::Response
    PAGI::Context
    PAGI::Session
    PAGI::Stash
    PAGI::WebSocket
    PAGI::SSE
    PAGI::Lifespan
    PAGI::Utils
    PAGI::Test::Client
    PAGI::Test::Response
);

for my $module (@core_modules) {
    my $file = $module;
    $file =~ s{::}{/}g;
    $file .= '.pm';
    my $loaded = eval { require $file; 1 };
    ok($loaded, "$module loads") or diag($@);
}

done_testing;
