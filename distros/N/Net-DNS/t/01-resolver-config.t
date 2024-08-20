#!/usr/bin/perl
# $Id: 01-resolver-config.t 1981 2024-06-17 13:22:14Z willem $	-*-perl-*-
#

use strict;
use warnings;
use IO::File;
use Test::More tests => 21;

use Net::DNS::Resolver;

local $ENV{'RES_NAMESERVERS'};
local $ENV{'RES_SEARCHLIST'};
local $ENV{'LOCALDOMAIN'};
local $ENV{'RES_OPTIONS'};

eval {
	my $fh = IO::File->new( '.resolv.conf', '>' ) || die $!;    # owned by effective UID
	close($fh);
};


my $resolver = Net::DNS::Resolver->new();
my $class    = ref($resolver);

my $isa = $resolver->OS_CONF;
diag $isa unless $isa =~ /::UNIX$/;

ok( $resolver->isa('Net::DNS::Resolver'), 'new() created object' );

ok( $class->new( debug => 1 )->_diag('_diag("debug message");'), 'debug message' );


$class->nameservers(qw(127.0.0.1 ::1));				# check class methods
ok( scalar( $class->nameservers ), '$class->nameservers' );
$class->searchlist(qw(sub1.example.com sub2.example.com));
ok( scalar( $class->searchlist ), '$class->searchlist' );
$class->domain('example.com');
ok( $class->domain,	   '$class->domain' );
ok( $class->srcport(1234), '$class->srcport' );
ok( $class->string(),	   '$class->string' );


ok( $resolver->domain('example.com'),	  '$resolver->domain' );       # check instance methods
ok( $resolver->searchlist('example.com'), '$resolver->searchlist' );
$resolver->nameservers(qw(127.0.0.1 ::1));
ok( scalar( $resolver->nameservers() ), '$resolver->nameservers' );
$resolver->nameservers();
is( scalar( $resolver->nameservers() ), 0, 'delete nameservers' );


$resolver->nameservers(qw(127.0.0.1 ::1 ::ffff:127.0.0.1 fe80::1234%1));
$resolver->force_v4(0);						# set by default if no IPv6
$resolver->prefer_v6(1);
my ($IPv6) = $resolver->nameserver();
is( $IPv6, '::1', '$resolver->prefer_v6(1)' );


$resolver->nameservers(qw(127.0.0.1 ::1));
$resolver->force_v6(0);
$resolver->prefer_v4(1);
my ($address) = $resolver->nameserver();
is( $address, '127.0.0.1', '$resolver->prefer_v4(1)' );


$resolver->force_v6(1);
ok( !$resolver->nameservers(qw(127.0.0.1)), '$resolver->force_v6(1)' );
like( $resolver->errorstring, '/IPv4.+disabled/', 'errorstring: IPv4 disabled' );


$resolver->force_v4(1);
ok( !$resolver->nameservers(qw(::)), '$resolver->force_v4(1)' );
like( $resolver->errorstring, '/IPv6.+disabled/', 'errorstring: IPv6 disabled' );


foreach my $ip (qw(127.0.0.1 ::1)) {
	is( $resolver->srcaddr($ip), $ip, "\$resolver->srcaddr($ip)" );
}


ok( $resolver->_hints(), 'parse defaults hints RRs' );		# check private methods callable
ok( $resolver->_hints(), 'defaults hints accessible' );


eval {					## no critic		# exercise printing functions
	my $object = Net::DNS::Resolver->new();
	my $file   = "01-resolver.tmp";
	my $handle = IO::File->new( $file, '>' ) || die "Could not open $file for writing";
	select( ( select($handle), $object->print )[0] );
	close($handle);
	unlink($file);
};


exit;

