#!/usr/bin/perl
#

use strict;
use warnings;
use Net::DNS 1.19;
use Net::DNS::Resolver::Unbound 1.29 -register;

my $resolver = Net::DNS::Resolver->new(
	debug_level => 2,
	prefer_v4   => 1,
	nameserver  => '1.1.1.1@853#cloudflare-dns.com',
	nameserver  => '8.8.8.8@853#dns.google',
	add_ta_file => '/var/lib/unbound/root.key',
	option	    => ['tls-cert-bundle' => '/etc/ssl/cert.pem'],
	set_tls	    => 1
	);

$resolver->print;

my @request = qw(example.net IN NS);

my $reply = $resolver->send(@request);

$reply->print unless $resolver->debug;

exit;

