#!/usr/bin/perl
#

use strict;
use warnings;
use Net::DNS 1.46;
use Net::DNS::Resolver::Unbound 1.29 -register;

my $resolver = Net::DNS::Resolver->new(
	add_ta_file => '/var/lib/unbound/root.key',
	debug_level => 2,
	nameservers => [],		## override /etc/resolv.conf
	);

$resolver->print;

my @request = qw(www.net-dns.org IN AAAA);

my $reply = $resolver->send(@request);
$reply->print unless $resolver->debug;

exit;

