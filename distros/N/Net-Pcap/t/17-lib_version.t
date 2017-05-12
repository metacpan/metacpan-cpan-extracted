#!perl -T
use strict;
use Test::More;
use Net::Pcap;

plan tests => 2;

# Testing lib_version()
my $version = eval { Net::Pcap::lib_version() };
is( $@, '', "lib_version()" );
diag($version);

if ($^O eq 'MSWin32' or $^O eq 'cygwin') {
    like( $version, '/^WinPcap version \d\.\d+/', " - checking version string ($version)" );
}
else {
    like( $version,
            '/^libpcap version (?:\d+\.\d+(?:\.\d+|[^\d.\s]+)?|unknown \(pre 0\.8\))/',
            " - checking version string ($version)"
    );
}
