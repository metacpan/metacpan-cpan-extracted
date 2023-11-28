#!/usr/bin/perl
#
#	Test multicast resolver functionality

use strict;
use warnings;
use Test::More tests => 3;

use Net::DNS::Multicast;

Net::DNS::Resolver->debug(0);
my @example = qw(_ipp._tcp.local. IN PTR);


for ( my $resolver = Net::DNS::Resolver->new( force_v6 => 1 ) ) {
	my $handle    = eval { $resolver->bgsend(@example) };
	my $exception = $@;
	ok( $handle, '$resolver->bgsend($multicast)	IPv6' ) || diag $exception;
}

for ( my $resolver = Net::DNS::Resolver->new( force_v4 => 1 ) ) {
	my $handle    = eval { $resolver->bgsend(@example) };
	my $exception = $@;
	ok( $handle, '$resolver->bgsend($multicast)	IPv4' ) || diag $exception;
}


for ( my $resolver = Net::DNS::Resolver->new( prefer_v6 => 1 ) ) {
	eval { $resolver->send(@example) };
	my $exception = $@;
	ok( !$exception, '$resolver->send($multicast)' ) || diag $exception;
}


exit;

__END__

