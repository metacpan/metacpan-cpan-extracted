use strict;
use warnings;
use Test2::V0;

# Core modules that must always load
my @core_modules = qw(
    PAGI::Server
    PAGI::Server::Connection
    PAGI::Server::ConnectionState
    PAGI::Server::EventValidator
    PAGI::Server::AsyncFile
    PAGI::Server::Protocol::HTTP1
    PAGI::Server::Runner
);

for my $module (@core_modules) {
    my $file = $module;
    $file =~ s{::}{/}g;
    $file .= '.pm';
    my $loaded = eval { require $file; 1 };
    ok($loaded, "$module loads") or diag($@);
}

# HTTP/2 protocol handler requires the optional Net::HTTP2::nghttp2
SKIP: {
    require PAGI::Server;
    skip "HTTP/2 support not available (install Net::HTTP2::nghttp2)", 1
        unless PAGI::Server->has_http2;
    my $loaded = eval { require PAGI::Server::Protocol::HTTP2; 1 };
    ok($loaded, 'PAGI::Server::Protocol::HTTP2 loads') or diag($@);
}

done_testing;
