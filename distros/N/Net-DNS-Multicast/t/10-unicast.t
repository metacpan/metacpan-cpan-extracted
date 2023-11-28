#!/usr/bin/perl
#
#	Test unicast Net::DNS resolver functionality

use strict;
use warnings;
use Test::More tests => 6;

use Net::DNS::Multicast;


my $resolver = Net::DNS::Resolver->new();
ok( $resolver, 'Net::DNS::Resolver->new(...)' );


my @example = qw(. NS);

ok( $resolver->send(@example), '$resolver->send($unicast)' );


my $handle = $resolver->bgsend(@example);
ok( $handle, '$resolver->bgsend($unicast)' );

my $reply = $resolver->bgread($handle);
ok( $reply, '$resolver->bgread($handle)' );

my $bgbusy = $resolver->bgbusy($handle);
ok( !$bgbusy, '$resolver->bgbusy($handle)' );

my $response = $resolver->bgread($handle);
ok( !$response, '$resolver->bgread($handle)' );


exit;

__END__

