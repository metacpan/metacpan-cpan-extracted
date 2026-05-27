#!/usr/bin/perl
#

use strict;
use warnings;
use Net::DNS 1.46;
use Net::DNS::Resolver::Unbound 1.29 -register;

my $resolver = Net::DNS::Resolver->new(
	add_ta_file => '/var/lib/unbound/root.key',
	debug_level => 2,
	nameserver  => '2606:4700:4700::1111@853#cloudflare-dns.com',
	nameserver  => '1.1.1.1@853#cloudflare-dns.com',
	nameserver  => '2001:4860:4860::8888@853#dns.google',
	nameserver  => '8.8.8.8@853#dns.google',
	option	    => ['tls-cert-bundle' => '/etc/ssl/cert.pem'],
	set_tls	    => 1
	);

$resolver->print;

my @request = qw(www.example.com IN AAAA);

my $reply = $resolver->send(@request);
$reply->print unless $resolver->debug;

exit;

