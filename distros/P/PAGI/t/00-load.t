use strict;
use warnings;
use Test2::V0;

# Core modules that must always load
my @core_modules = qw(
    PAGI::Server
    PAGI::Server::Connection
    PAGI::Server::Protocol::HTTP1
    PAGI::App::WrapPSGI
    PAGI::Request::Negotiate
    PAGI::Request::Upload
);

# Test core modules
for my $module (@core_modules) {
    my $file = $module;
    $file =~ s{::}{/}g;
    $file .= '.pm';
    my $loaded = eval { require $file; 1 };
    ok($loaded, "load $module") or diag $@;
}

done_testing;
