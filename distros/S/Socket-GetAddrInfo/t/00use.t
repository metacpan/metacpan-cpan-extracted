#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

use_ok( "Socket::GetAddrInfo" );
use_ok( "Socket::GetAddrInfo::Socket6api" );
use_ok( "Socket::GetAddrInfo::Strict" );

# Declare which case is being used; can be useful in test reports

if( defined $Socket::GetAddrInfo::Emul::VERSION ) {
   diag "Using emulation using legacy resolvers";
}
elsif( defined $Socket::GetAddrInfo::XS::VERSION ) {
   diag "Using native getaddrinfo(3) from XS";
}
else {
   diag "Using native getaddrinfo(3) from core";
}

# Also declare the contents of config.h
if( open my $configh, "<", "config.h" ) {
   my $config = do { local $/; <$configh> };
   diag "config.h is:\n---\n$config---";
}
