#!/usr/bin/env perl

use Test::More;
use lib::abs '../lib';
use Socket::AcceptFilter;
use Socket qw(AF_INET SOCK_STREAM SOL_SOCKET);

my $fh;
socket $fh, AF_INET, SOCK_STREAM, 0
	or plan skip_all => "socket failed: $!";
bind $fh, Socket::pack_sockaddr_in(65529, Socket::inet_aton('127.0.0.1'))
	or plan skip_all => "bind failed: $!";
my ($service, $host) = Socket::unpack_sockaddr_in getsockname $fh;
diag "bind to ".join( ".", unpack "C4",$host).":$service";
listen $fh,10 or plan skip_all => "listen failed: $!";

if ($^O eq 'freebsd') {
	plan tests => 1;
	SKIP:{
		my $rc = accept_filter($fh,'dataready');
		if(!$rc) {
			my $mod = 'accf_data';
			my $res = `/sbin/kldstat -m $mod`;
			!$res and $! and skip "failed to call kldstat: $!", 1;
			$res =~ /\d+\s+\d+\s+$mod/s or skip "$mod not loaded", 1;
		}
		ok $rc, 'freebsd dataready';
	}
}
elsif ($^O eq 'linux') {
	plan tests => 1;
	ok accept_filter($fh,'dataready');
}
else {
	plan skip_all => "$^O not supported";
}
